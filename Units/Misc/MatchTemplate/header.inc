{$mode objfpc}{$H+}
{$macro on}
{$inline on}

{$ASMMODE INTEL}

{$OPTIMIZATION LOOPUNROLL}

{$IF FPC_VERSION >= 3}
  {$OPTIMIZATION FASTMATH}
{$ENDIF}

{$IF Defined(CPU386)}
  {$FPUTYPE SSE3}
{$ELSEIF Defined(CPUX86_64)}
  {$FPUTYPE SSE64}
{$ENDIF}

{$DEFINE callconv}
{$IF DEFINED(WINDOWS) OR DEFINED(LINUX) OR DEFINED(DARWIN)}
  {$IFDEF CPU32}
    {$UNDEF callconv}
    {$DEFINE callconv := cdecl;}
  {$ENDIF}
{$ENDIF}

{$modeswitch advancedrecords}
