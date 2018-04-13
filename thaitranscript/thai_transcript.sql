/*

Thai to Latin transcription code via PyThaiNLP library
https://github.com/PyThaiNLP/pythainlp

Hopefully using Royal Thai General System of Transcription (RTGS)

(c) 2018 Sven Geggus <svn-osm@geggus.net>

*/

CREATE or REPLACE FUNCTION osml10n_thai_transcript(inpstr text) RETURNS TEXT AS $$
  import unicodedata
  import plpy

  def split_by_alphabet(str):
    strlist=[]
    target=''
    oldalphabet=unicodedata.name(str[0]).split(' ')[0]
    target=str[0]
    for c in str[1:]:
      alphabet=unicodedata.name(c).split(' ')[0]
      if (alphabet==oldalphabet):
        target=target+c
      else:
        strlist.append(target)
        target=c
      oldalphabet=alphabet
    strlist.append(target)
    return(strlist)
  
  try:
    from pythainlp.romanization import romanization
    from pythainlp.tokenize import word_tokenize
  except:
    plpy.notice("pythainlp not installed, falling back to ICU")
    return(None)
  
  stlist=split_by_alphabet(inpstr)
  
  latin = ''
  for st in stlist:
    if (unicodedata.name(st[0]).split(' ')[0] == 'THAI'):
      transcript=[]
      for w in word_tokenize(st):
        try:
          transcript.append(romanization(w,engine='royin'))
        except:
          plpy.notice("thainlp error transcribing >%s<" % w)
          return(None)
      latin=latin+' '.join(transcript)
    else:
      latin=latin+st
  return(latin)
$$ LANGUAGE plpython3u STABLE;
