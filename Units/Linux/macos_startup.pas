unit macos_startup;

{$mode objfpc}{$H+}

interface

uses
  pthreads;

implementation

initialization
  pthread_setcancelstate(PTHREAD_CANCEL_ENABLE, nil); // for script thread force terminate

end.
