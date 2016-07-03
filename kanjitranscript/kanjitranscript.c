/*
 
Load using the following command:
CREATE FUNCTION osml10n_kanji_transcript(text) RETURNS text
AS '/path/to/osml10n_kanjitranscript.so', 'osml10n_kanji_transcript' LANGUAGE C STRICT;

(c) 2015 Sven Geggus <sven-osm@geggus.net>

Licence AGPL http://www.gnu.org/licenses/agpl-3.0.de.html

*/
#include <postgres.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <libkakasi.h>
#include <mb/pg_wchar.h>
#include <fmgr.h>
#include <iconv.h>
#include <utf8proc.h>
#include <wchar.h>

#ifdef PG_MODULE_MAGIC
PG_MODULE_MAGIC;
#endif

PG_FUNCTION_INFO_V1(osml10n_kanji_transcript);

static int utf8_strlen(char *s) {
  int i = 0, j = 0;
  while (s[i]) {
    if ((s[i] & 0xc0) != 0x80) j++;
    i++;
  }
  return j;
}

Datum osml10n_kanji_transcript(PG_FUNCTION_ARGS) {
  char *inbuf;
  char *normalized;
  wchar_t *normalized_wc;
  size_t numchars;
  unsigned i;
  char *kakasi_out;
  char *kakasi_argv[6]={"kakasi","-Ja","-Ha","-Ka","-Ea","-s"};
  
  if (GetDatabaseEncoding() != PG_UTF8) {
    ereport(ERROR,(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
    errmsg("requires UTF8 database encoding")));
    PG_RETURN_NULL();
  }
   
  text *t = PG_GETARG_TEXT_P(0);

  inbuf=(char *) malloc((VARSIZE(t) - VARHDRSZ +1)*sizeof(char));
  memcpy(inbuf, (void *) VARDATA(t), VARSIZE(t) - VARHDRSZ);
  inbuf[VARSIZE(t) - VARHDRSZ]='\0';
  
  // 1. Use Normalization Form KC to avoid Enclosed CJK Letters like
  // https://en.wikipedia.org/wiki/Enclosed_CJK_Letters_and_Months
  // which are unavailabe in EUC-JP encoding
  // Example: ㈱ PARENTHESIZED IDEOGRAPH STOCK
  normalized=utf8proc_NFKC(inbuf);
  if (NULL == normalized) {
    ereport(ERROR, (errmsg("error calling utf8proc_NFKC")));
    free(inbuf);
    PG_RETURN_NULL();
  }
  free(inbuf);
  
  // 2. convert utf-8 to wchar
  // This is likely not verry portable to anything else
  // than GNU/Linux :)
  // numchars is number of normalized unicode characters
  numchars=mbstowcs(NULL,normalized,0);
  normalized_wc=malloc((numchars+1)*sizeof(wchar_t));
  mbstowcs(normalized_wc,normalized,numchars+1);
  free(normalized);
  
  // 3. convert encoding to euc-jp to make it usable for kakasi
  // do this character by character and ignore haracters where
  // conversion failed
  
  // create transcoder from wchar to EUC-JP
  iconv_t wc2euc = iconv_open("EUC-JP", "WCHAR_T");
  if(wc2euc == (iconv_t) -1) {
      ereport(ERROR, (errmsg("iconv Initialization failure")));
      PG_RETURN_NULL();
  }
   
  // len of wchar
  size_t ibl = numchars*sizeof(wchar_t);;
  // len of eucjp is maximum 3 bytes per char + 0-terminator
  size_t obl =  numchars*3+1;
  size_t clen_in = sizeof(wchar_t);
  size_t clen_out = sizeof(wchar_t);
         
  char *converted = calloc(obl, sizeof(char));
  char *converted_start = converted;
  char *single_euc = calloc(4, sizeof(char));
  char *single_euc_start = single_euc;
  
  // convert wchat to eucjp
  // do this character by character and ignore
  // characters where conversion failed  
  char *iconv_in;
  size_t euclen; 
  for (i=0;i<wcslen(normalized_wc);i++) {
    iconv_in = (char *)&normalized_wc[i];
    clen_in = clen_out = sizeof(wchar_t);
    int ret = iconv(wc2euc,&iconv_in,&clen_in, &single_euc, &clen_out);
    // copy EUC-JP character to output if conversion succeeded
    if(ret != (size_t) -1) {
      euclen=sizeof(wchar_t)-clen_out;
      memcpy(converted,single_euc_start,euclen);
      converted+=euclen;
    }
    single_euc=single_euc_start;
  }
  // 0-terminate EUC-JP string
  converted='\0';
  free(single_euc_start);  
  iconv_close(wc2euc);
  free(normalized_wc);

  // EUC-JP string is empty
  if (strlen(converted_start)==0) {
    free(converted_start);
    PG_RETURN_NULL();
  }
  
  // 4. run kakasi transliteration
  
  // run kakasi on eucjp string
  kakasi_getopt_argv(6,kakasi_argv);
  kakasi_out=kakasi_do(converted_start);
  free(converted_start);
  if (kakasi_out==NULL) {
    ereport(ERROR, (errmsg("kakasi_do failed")));
    PG_RETURN_NULL();
  }
  
  // 5. write kakasi output to psql buffer        
  int32_t obufLen = strlen(kakasi_out);
  
  text *new_text = (text *) palloc(VARHDRSZ + obufLen);
  SET_VARSIZE(new_text, VARHDRSZ + obufLen);
  memcpy((void *) VARDATA(new_text), /* destination */
         (void *) kakasi_out,obufLen);
  kakasi_free(kakasi_out);
  PG_RETURN_TEXT_P(new_text);
}
