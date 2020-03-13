all:
	./rebar3 get-deps compile

compile:
	./rebar3 compile

clean:
	./rebar3 clean -a

test:
	DEBUG=1 ./rebar3 eunit

dialyze:
	./rebar3 as dialyzer dialyzer

xref:
	./rebar3 as test xref

.PHONY: all compile clean test dialyze
