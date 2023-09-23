import "dart:async";
import "dart:io";
import "dart:convert";
import "dart:typed_data";

import "Log.dart";
import "Hash.dart";
import "FileIO.dart";
import "ProgressBar.dart";

Future<void> SendFile(Socket socket, String path, int pathStart) async
{
  ProgressBar.Init();
  final FileIO file = FileIO();
  if (!file.Open(path, FileMode.read)) return;
  final Sha256 s = Sha256();
  final int totalSize = file.Size();
  int bytes = totalSize;
  socket.add(ascii.encode("${path.substring(pathStart)}|$bytes|"));

  while (bytes > 0)
  {
    Uint8List buffer = file.ReadChunk(1024);
    ProgressBar.Show(totalSize - bytes, totalSize);
    s.Update(buffer);
    socket.add(buffer);
    await socket.flush();
    bytes -= buffer.length;
  }

  file.Close();
  s.Finalize();
  Log("${path.substring(pathStart)}: ${s.Hexdigest()}");
  socket.add(ascii.encode(s.Hexdigest()));
}


Future<void> SendDirectory(Socket socket, List<List<dynamic>> files, int pathStart) async
{
  bool finished = false;
  socket.listen((event) { finished = true; }, onError: (error){} ); // receiver writes one byte to indicate it's ready for the next send

  try
  {
    for (List<dynamic> path in files)
    {
      if (path[1] == false) await SendFile(socket, path[0], pathStart);
      else // is an empty folder
      {
        socket.add(ascii.encode("${path[0].substring(pathStart)}|-1|e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"));
      }
      await socket.flush();
      while (!finished) await Future.delayed(Duration(milliseconds: 200));
      finished = false;
    }
  }
  on SocketException catch(e)
  {
    Err("Failed to send data (${e.message})");
    if (e.osError != null) VerErr("${e.osError}");
  }
}


Future<void> Send(String ip, int port, String path) async
{
  // structure: 13|filename|10|oooooooooodccc4ea2435223f6cf2a7d84f223e79db6f5b730ff78df0f72e6fce
  //            ^ 1 = folder, 0 = single file
  //             ^ number of files (will be 1 if not a folder) (These two are only on the first send)
  //                        ^ bytes in next file (if 0 it's an empty directory)
  //                           ^ start of bytes
  //                                         ^ start of hash (64 bytes)
  // if it's a folder then filename is relative to the folder
  if (FileIO.IsEmptyDir(path))
  {
    Err("Can't send an empty directory");
    return;
  }

  String seperator = path.contains("/") ? "/" : "\\";
  final parts = path.split(seperator);
  String tmp = parts[parts.length - 1];

  Socket? socket = await SetupSocketSender(ip, port);
  if (socket == null) return;

  if (FileIO.IsDirectory(path))
  {
    final list = FileIO.GetDirectoryContent(path);
    socket.add(ascii.encode("1${list.length}|"));
    await SendDirectory(socket, list, path.length-tmp.length);
  }
  else
  {
    socket.add(ascii.encode("01|"));
    final List<List<dynamic>> list = [[path, false]]; // create dummy directory list
    await SendDirectory(socket, list, path.length-tmp.length);
  }
  socket.destroy();
}


Future<Socket?> SetupSocketSender(String ip, int port) async
{
  Ver("Sender");
  try
  {
    Socket socket = await Socket.connect(ip, port);
    Ver("Connected");
    return socket;
  }
  on SocketException catch(e)
  {
    Err("Failed to connect to $ip on port $port reason: ${e.message}");
    if (e.osError != null) VerErr("${e.osError}");
  }
  on ArgumentError catch(e)
  {
    Err(e.toString());
  }
  catch(e)
  {
    Err("Unknown exception: $e");
  }
  return null;
}