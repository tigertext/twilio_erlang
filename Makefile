all:
	rebar3 compile

clean:
	rebar3 clean -a

test:
	rebar3 eunit

dialyze:
	rebar3 dialyzer

xref:
	rebar3 xref
