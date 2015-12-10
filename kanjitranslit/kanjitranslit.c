/*
 
Load using the following command:
CREATE FUNCTION kanji_transliterate(text) RETURNS text
AS '/path/to/kanjitranslit.so', 'kanji_transliterate' LANGUAGE C STRICT;

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

#ifdef PG_MODULE_MAGIC
PG_MODULE_MAGIC;
#endif

PG_FUNCTION_INFO_V1(kanji_transliterate);

static int utf8_strlen(char *s) {
  int i = 0, j = 0;
  while (s[i]) {
    if ((s[i] & 0xc0) != 0x80) j++;
    i++;
  }
  return j;
}

Datum kanji_transliterate(PG_FUNCTION_ARGS) {
  char *inbuf;
  char *kakasi_out;
  char *kakasi_argv[6]={"kakasi","-Ja","-Ha","-Ka","-Ea","-s"};
  
  if (GetDatabaseEncoding() != PG_UTF8) {
    ereport(ERROR,(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
    errmsg("requires UTF8 database encoding")));
    PG_RETURN_TEXT_P("");
  }
   
  text *t = PG_GETARG_TEXT_P(0);

  inbuf=(char *) malloc((VARSIZE(t) - VARHDRSZ +1)*sizeof(char));
  memcpy(inbuf, (void *) VARDATA(t), VARSIZE(t) - VARHDRSZ);
  inbuf[VARSIZE(t) - VARHDRSZ]='\0';
  
  // 1. convert encoding to euc-jp to make it usable for kakasi
  
  // create transcoder from utf8 to EUC-JP
  iconv_t euc2utf = iconv_open("EUC-JP", "UTF-8");
  if(euc2utf == (iconv_t) -1) {
      ereport(ERROR, (errmsg("iconv Initialization failure")));
  }
   
  // len of utf 
  size_t ibl = strlen(inbuf)+1;
  // len of eucjp is maximum 3 bytes per char
  size_t obl =  utf8_strlen(inbuf)*3+1;
         
  char *converted = calloc(obl, sizeof(char));
  char *converted_start = converted;
  char *inbuf_start = inbuf;
  
  int ret = iconv(euc2utf,&inbuf,&ibl, &converted, &obl);
  if(ret == (size_t) -1) {
    ereport(ERROR, (errmsg("string conversion of to EUC-JP (iconv) failed")));
    iconv_close(euc2utf);
    PG_RETURN_TEXT_P("");
  }
  
  iconv_close(euc2utf);
  free(inbuf_start);
  
  // 2. run kakasi transliteration
  
  // run kakasi on eucjp string
  kakasi_getopt_argv(6,kakasi_argv);
  kakasi_out=kakasi_do(converted_start);
  free(converted_start);
  if (kakasi_out==NULL) {
    ereport(ERROR, (errmsg("kakasi_do failed")));
    PG_RETURN_TEXT_P("");
  }
  
  // 3. write kakasi output to psql buffer        
  int32_t obufLen = strlen(kakasi_out);
  
  text *new_text = (text *) palloc(VARHDRSZ + obufLen);
  SET_VARSIZE(new_text, VARHDRSZ + obufLen);
  memcpy((void *) VARDATA(new_text), /* destination */
         (void *) kakasi_out,obufLen);
  kakasi_free(kakasi_out);
  PG_RETURN_TEXT_P(new_text);
}
