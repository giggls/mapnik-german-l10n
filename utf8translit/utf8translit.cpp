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
  UErrorCode tlstatus = U_ZERO_ERROR;
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
   
  latin_tl = Transliterator::createInstance("Any-Latin", UTRANS_FORWARD, tlstatus);
  if (latin_tl == 0) {
    ereport(ERROR,(errcode(ERRCODE_SYSTEM_ERROR),
    errmsg("ERROR: Transliterator::createInstance() failed")));
    PG_RETURN_TEXT_P("");
  }
  latin_tl->transliterate(ustr);

  int32_t len = ustr.length();
  int32_t bufLen = len + 16;
  int32_t actualLen;
  outbuf=(char *) malloc((bufLen +1)*sizeof(char));
  
  actualLen = ustr.extract(0, len, outbuf);
  outbuf[actualLen] = '\0';
   
  text *new_text = (text *) palloc(VARHDRSZ + actualLen);
  SET_VARSIZE(new_text, VARHDRSZ + actualLen);   
  memcpy((void *) VARDATA(new_text), /* destination */
         (void *) outbuf,actualLen);

  free(inbuf);
  free(outbuf);
  delete latin_tl;       
  PG_RETURN_TEXT_P(new_text);
}

} /* extern "C" */

