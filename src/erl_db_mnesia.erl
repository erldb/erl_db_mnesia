%%%-------------------------------------------------------------------
%%% @author daniel <>
%%% @copyright (C) 2013, daniel
%%% @doc
%%%
%%% @end
%%% Created :  1 Aug 2013 by daniel <>
%%%-------------------------------------------------------------------
-module(erl_db_mnesia).

-behaviour(gen_server).

%% API
-export([start_link/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_info/2,
         terminate/2, code_change/3]).

-define(SERVER, ?MODULE).

-record(state, {}).

%%%===================================================================
%%% API
%%%===================================================================

%%--------------------------------------------------------------------
%% @doc
%% Starts the server
%%
%% @spec start_link() -> {ok, Pid} | ignore | {error, Error}
%% @end
%%--------------------------------------------------------------------
start_link() ->
    WorkerArgs = proplists:get_value(worker_args, Args, []),
    gen_server:start_link({local, ?SERVER}, ?MODULE, WorkerArgs, []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Initializes the server
%%
%% @spec init(Args) -> {ok, State} |
%%                     {ok, State, Timeout} |
%%                     ignore |
%%                     {stop, Reason}
%% @end
%%--------------------------------------------------------------------
init(Args) ->
    ensure_tables(Args),
    {ok, #state{}}.

ensure_tables(Args) ->
    %% Here it should be some checks for tables.
    Args.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling call messages
%%
%% @spec handle_call(Request, From, State) ->
%%                                   {reply, Reply, State} |
%%                                   {reply, Reply, State, Timeout} |
%%                                   {noreply, State} |
%%                                   {noreply, State, Timeout} |
%%                                   {stop, Reason, Reply, State} |
%%                                   {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
handle_call({read, Table, Key}, _From, State) ->
    Reply = transaction(read, Table, Key),
    {reply, Reply, State};
handle_call({write, Table, Object}, _From, State) ->
    WriteResp = transaction(write, Table, Object)
    {reply, Reply, State};
handle_call({delete, Table, Key}, _From, State) ->
    Reply = transaction(delete, Table, Key),
    {reply, Reply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling all non call/cast messages
%%
%% @spec handle_info(Info, State) -> {noreply, State} |
%%                                   {noreply, State, Timeout} |
%%                                   {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
handle_info(_Info, State) ->
    {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called by a gen_server when it is about to
%% terminate. It should be the opposite of Module:init/1 and do any
%% necessary cleaning up. When it returns, the gen_server terminates
%% with Reason. The return value is ignored.
%%
%% @spec terminate(Reason, State) -> void()
%% @end
%%--------------------------------------------------------------------
terminate(_Reason, _State) ->
    ok.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Convert process state when code is changed
%%
%% @spec code_change(OldVsn, State, Extra) -> {ok, NewState}
%% @end
%%--------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================
transaction(read, Tab, Key) ->
    Transaction =
        mnesia:transaction(
          fun() ->
                  mnesia:read(Tab, Key)
          end),
    case Transaction of
        {atomic, Response} -> Response;
        {aborted, Reason} -> Reason
    end;
transaction(write, Tab, Object) ->
    Transaction =
        mnesia:transaction(
          fun() ->
                  mnesia:write(Tab, Object, write)
          end),
    case Transaction of
        {atomic, Response} -> Response;
        {aborted, Reason} -> Reason
    end;
transaction(delete, Tab, Key) ->
    Transaction =
        mnesia:transaction(
          fun() ->
                  mnesia:delete(Tab, Key, write)
          end),
    case Transaction of
        {atomic, Response} -> Response;
        {aborted, Reason} -> Reason
    end.