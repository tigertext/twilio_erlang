%%%-------------------------------------------------------------------
%%% @author Ryan Huffman <ryanhuffman@gmail.com>
%%% @copyright 2011, Ryan Huffman
%%% @doc Twilio REST API library.  Uses API version "2010-04-01".
%%%
%%% @end
%%%-------------------------------------------------------------------
-module(twilio).

-export([make_call/5,
    send_sms/5, send_sms_using_messaging_service/5]).
-export([request/5]).

-define(BASE_URL, "api.twilio.com").
-define(API_VERSION_2010, "2010-04-01").

-type twilio_response() :: any().
-type twilio_param() :: {string(), string()}.

%% @doc Makes a call.  Opts is a list of parameters to send
%% to twilio.  The list of accepted parameters can be found
%% at [http://www.twilio.com/docs/api/rest/making_calls].
%% One of "Url" or "ApplicationSid" must be provided.
-spec make_call(string(), string(), string(), string(), [twilio_param()]) -> twilio_response().
make_call(AccountSID, AuthToken, From, To, Params) ->
    % Add "From" and "To" parameters to send to twilio
    Params2 = [{"From", From}, {"To", To} | Params],

    Path = "/Accounts/" ++ AccountSID ++ "/Calls.json",

    request(AccountSID, AuthToken, post, Path, Params2).

%% @doc Sends an SMS.  Opts is a list of parameters to send
%% to twilio.  The list of accepted parameters can be found
%% at [http://www.twilio.com/docs/api/rest/making_calls].
%% One of "Url" or "ApplicationSid" must be provided.
-spec send_sms(string(), string(), string(), string(), string()) -> twilio_response().
send_sms(AccountSID, AuthToken, From, To, Body) ->
    send_sms_using({"From", From}, AccountSID, AuthToken, To, Body).

%% @doc Sends an SMS using a messaging service. Reference: [https://www.twilio.com/docs/api/rest/sending-messages#messaging-services]
-spec send_sms_using_messaging_service(string(), string(), string(), string(), string()) -> twilio_response().
send_sms_using_messaging_service(AccountSID, AuthToken, MessagingServiceSid, To, Body) ->
    send_sms_using({"MessagingServiceSid", MessagingServiceSid}, AccountSID, AuthToken, To, Body).

send_sms_using(Sender_Param, AccountSID, AuthToken, To, Body) ->
    % Add "From" and "To" parameters to send to twilio
    Params2 = [Sender_Param, {"To", To}, {"Body", Body}],

    Path = "/Accounts/" ++ AccountSID ++ "/Messages",

    request(AccountSID, AuthToken, post, Path, Params2).

%% @doc Makes a Twilio API request.
-spec request(string(), string(), atom(), string(), [{string(), string()}]) -> twilio_response().
request(AccountSID, AuthToken, get, Path, []) ->
    RequestURL = "https://" ++ AccountSID ++ ":" ++ AuthToken
                 ++ "@"?BASE_URL"/"?API_VERSION_2010 ++ Path,
    Request = {RequestURL, [{"Accept", "application/json"}]},
    case httpc:request(get, Request, [], []) of
        {ok, {{_, 200, _}, _, R}} ->
            {ok, R};
        {ok, {{_, N, _}, RH, RB}} ->
            Twilio_Id = proplists:get_value("twilio-request-id", RH, "N/A"),
            {error, "Status " ++ integer_to_list(N) ++ ", Twilio Req. ID: " ++ Twilio_Id ++ ", Details: " ++ to_string(RB)};
        {error, _} = Error ->
            {error, Error}
    end;
request(AccountSID, AuthToken, post, Path, Params) ->
    RequestURL = "https://" ++ AccountSID ++ ":" ++ AuthToken
                 ++ "@"?BASE_URL"/"?API_VERSION_2010 ++ Path,
    
    ParamsString = expand_params(Params),
    Request = {RequestURL, [], "application/x-www-form-urlencoded", ParamsString},
    % @TODO properly parse for twilio errors
    case httpc:request(post, Request, [], []) of
        {ok, {{_, 201, _}, _, _}} ->
            {ok, ok};
        {ok, {{_, N, _}, RH, RB}} ->
            Twilio_Id = proplists:get_value("twilio-request-id", RH, "N/A"),
            {error, "Status " ++ integer_to_list(N) ++ ", Twilio Req. ID: " ++ Twilio_Id ++ ", Details: " ++ to_string(RB)};
        {error, _} = Error ->
            {error, Error}
    end.

%% @doc Expands a list of twilio parameters to a URL escaped query string.
-spec expand_params([twilio_param()]) -> string().
expand_params(Params) ->
    ParamStrings = [edoc_lib:escape_uri(Name) ++ "=" ++ edoc_lib:escape_uri(Value)
              || {Name, Value} <- Params],
    string:join(ParamStrings, "&").

to_string(B) when is_binary(B)  -> binary_to_list(B);
to_string(S) when is_list(S)    -> S;
to_string(Etc)                  -> binary_to_list(term_to_binary(Etc)).

-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").

expand_params_test() ->
    ?assertEqual("From=1234", expand_params([{"From", "1234"}])),
    ?assertEqual("SomeName=%24Ryan", expand_params([{"SomeName", "$Ryan"}])),
    ?assertEqual("%24From=1234&To=2341&SomeName=%24Ryan",
        expand_params([{"$From", "1234"}, {"To", "2341"}, {"SomeName", "$Ryan"}])).

-endif.

