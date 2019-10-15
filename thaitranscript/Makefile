osml10n_thai_transcript.py: thai_transcript.sql
	./gen_raw_py

test: osml10n_thai_transcript.py
	@echo "running osml10n_thai_transcript.py:"
	@echo -n "got:       "
	@./osml10n_thai_transcript.py ถนนข้าวสาร
	@echo -n "should be: "
	@echo "thanon khawsan"	

clean:
	rm osml10n_thai_transcript.py	