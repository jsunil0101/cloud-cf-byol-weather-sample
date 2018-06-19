-module(geo_server_sup).
-behaviour(supervisor).

-author("Chris Whealy <chris.whealy@sap.com>").
-revision("Revision: 1.0.0").
-created("Date: 2018/02/02 13:17:39").
-created_by("chris.whealy@sap.com").

-export([
   start/2
 , stop/1
 , init/1
]).

-include("../include/macros/trace.hrl").

-define(RESTART_STRATEGY, one_for_one).
-define(MAX_RESTARTS, 1).
-define(RESTART_PERIOD, 5).

-define(RESTART_TUPLE, {?RESTART_STRATEGY, ?MAX_RESTARTS, ?RESTART_PERIOD}).

%% =====================================================================================================================
%%
%%                                                 P U B L I C   A P I
%%
%% =====================================================================================================================

%% ---------------------------------------------------------------------------------------------------------------------
%% Start geo_server supervisor
start(Countries, ProxyInfo) ->
  supervisor:start_link({local, ?MODULE}, ?MODULE, {Countries, ProxyInfo}).


%% ---------------------------------------------------------------------------------------------------------------------
%% Initialise server
init({Countries, ProxyInfo}) ->
  %% Keep trace on in order to log server startup
  put(trace, true),
  ?TRACE("Supervisor initialising country_manager with ~p countries",[length(Countries)]),

  { ok
  , { ?RESTART_TUPLE
    , [ { country_manager
        , { country_manager
          , init
          , [Countries, ProxyInfo]
          }
        , permanent
        , brutal_kill
        , supervisor
        , [country_manager]
        }
      ]
    }
  }.


%% ---------------------------------------------------------------------------------------------------------------------
%% Stop server
stop(_State) ->
  ?TRACE("Supervisor shutting down"),

  %% Tell the country_manager to shut down
  country_manager ! {cmd, terminate, self()},

  % Wait for shutdown response
  receive
    {cmd_response, _FromServer, _Cmd, goodbye, _Reason, _Payload} ->
      exit(normal);

    SomeVal ->
      ?LOG("geo_server supervisor received an unexpected message after issuing the 'terminate' command: ~p",[SomeVal]),
      exit({supervisor_shutdown_error, SomeVal})
  end.

