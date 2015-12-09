/*
 
Load using the following command:
CREATE FUNCTION transliterate(text) RETURNS text
AS '/path/to/utf8trans.so', 'transliterate' LANGUAGE C STRICT;

(c) 2013 Sven Geggus <sven-osm@geggus.net>

Licence AGPL http://www.gnu.org/licenses/agpl-3.0.de.html

*/
#include <iostream>
#include <unicode/unistr.h>
#include <unicode/translit.h>

extern "C" {

#include <postgres.h>
#include <stdlib.h>
#include <string.h>
#include <mb/pg_wchar.h>
#include <fmgr.h>

#ifdef PG_MODULE_MAGIC
PG_MODULE_MAGIC;
#endif

PG_FUNCTION_INFO_V1(transliterate);

Datum transliterate(PG_FUNCTION_ARGS) {
  Transliterator *latin_tl;
  UErrorCode status = U_ZERO_ERROR;
  char *inbuf,*outbuf;
  
  if (GetDatabaseEncoding() != PG_UTF8) {
    ereport(ERROR,(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
    errmsg("requires UTF8 database encoding")));
  }
   
  text *t = PG_GETARG_TEXT_P(0);

  inbuf=(char *) malloc((VARSIZE(t) - VARHDRSZ +1)*sizeof(char));
  memcpy(inbuf, (void *) VARDATA(t), VARSIZE(t) - VARHDRSZ);
  inbuf[VARSIZE(t) - VARHDRSZ]='\0';
   
  UnicodeString ustr(inbuf);
  latin_tl = Transliterator::createInstance("Any-Latin", UTRANS_FORWARD, status);
  if (latin_tl == 0) {
    ereport(ERROR,(errcode(ERRCODE_SYSTEM_ERROR),
    errmsg("ERROR: Transliterator::createInstance() failed")));
    PG_RETURN_TEXT_P("");
  }
  latin_tl->transliterate(ustr);
  
  
  int32_t bufLen = 100;
  outbuf = (char *) malloc((bufLen + 1)*sizeof(char));
  status=U_ZERO_ERROR;
  bufLen = ustr.extract(outbuf,bufLen,NULL,status);
  if (status == U_BUFFER_OVERFLOW_ERROR) {
    status=U_ZERO_ERROR;
    outbuf = (char *) realloc(outbuf, bufLen + 1);
    bufLen = ustr.extract(outbuf,bufLen,NULL,status);
  }
  outbuf[bufLen] = '\0'; 
  
  text *new_text = (text *) palloc(VARHDRSZ + bufLen);
  SET_VARSIZE(new_text, VARHDRSZ + bufLen);
  memcpy((void *) VARDATA(new_text), /* destination */
         (void *) outbuf,bufLen);
  
  free(inbuf);
  free(outbuf);
  delete latin_tl;       
  PG_RETURN_TEXT_P(new_text);
}

} /* extern "C" */

