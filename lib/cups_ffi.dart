import 'dart:ffi' as ffi;
import 'dart:io';

import 'src/cups_native.dart';
import 'package:ffi/ffi.dart';

export 'src/cups_native.dart';
export 'src/cups_format.dart';

const IPP_STATUS_OK = 0;
const EXCEPT = -1;

final ffi.DynamicLibrary Function() _loadLibrary = () {
  if (Platform.isMacOS) {
    return ffi.DynamicLibrary.open(
        '${Directory.current.parent.path}/cups-2.3.3/libcups.dylib');
  } else if (Platform.isLinux) {
    return ffi.DynamicLibrary.open(
        '${Directory.current.parent.path}/cups-2.3.3/libcups.so.2');
  }
  throw UnsupportedError("Platform not supported!");
};

final _cups = CupsNative(_loadLibrary());

// void _wrappedPrint(ffi.Pointer<Utf8> arg) {
//   print(arg.toDartString());
// }

// typedef _wrappedPrint_C = ffi.Void Function(ffi.Pointer<Utf8> a);
// final _wrappedPrintPointer =
//     ffi.Pointer.fromFunction<_wrappedPrint_C>(_wrappedPrint);

bool printRawText(
    String format, String printerName, String jobName, String text) {
  //_cups.initialize(_wrappedPrintPointer);
  ffi.Pointer<http_t> CUPS_HTTP_DEFAULT = ffi.nullptr;
  bool result = false;
  var printerNamePtr = printerName.toNativeUtf8().cast<ffi.Int8>();
  var jobNamePtr = jobName.toNativeUtf8().cast<ffi.Int8>();
  var jobId = _cups.cupsCreateJob(
      ffi.nullptr, printerNamePtr, jobNamePtr, 0, ffi.nullptr);
  if (jobId > 0) {
    var formatPtr = format.toNativeUtf8().cast<ffi.Int8>();
    var textPtr = text.toNativeUtf8().cast<ffi.Int8>();
    var httpResult = _cups.cupsStartDocument(
        CUPS_HTTP_DEFAULT, printerNamePtr, jobId, textPtr, formatPtr, 1);
    if (httpResult == 100) {
      httpResult = _cups.cupsWriteRequestData(
          CUPS_HTTP_DEFAULT, textPtr, text.codeUnits.length);
      if (httpResult == 100) {
        var status =
            _cups.cupsFinishDocument(CUPS_HTTP_DEFAULT.cast(), printerNamePtr);
        if (status == IPP_STATUS_OK) {
          result = true;
        }
      }
    }
    calloc.free(formatPtr);
    calloc.free(textPtr);
  }
  calloc.free(CUPS_HTTP_DEFAULT);
  calloc.free(printerNamePtr);
  calloc.free(jobNamePtr);
  return result;
}

bool printRawData(
    String format, String printerName, String jobName, List<int> data) {
  //_cups.initialize(_wrappedPrintPointer);
  ffi.Pointer<http_t> CUPS_HTTP_DEFAULT = ffi.nullptr;
  bool result = false;
  var printerNamePtr = printerName.toNativeUtf8().cast<ffi.Int8>();
  var jobNamePtr = jobName.toNativeUtf8().cast<ffi.Int8>();
  var jobId = _cups.cupsCreateJob(
      ffi.nullptr, printerNamePtr, jobNamePtr, 0, ffi.nullptr);
  if (jobId > 0) {
    var formatPtr = format.toNativeUtf8().cast<ffi.Int8>();
    var dataPtr = calloc<ffi.Int8>(data.length);
    dataPtr.asTypedList(data.length).setAll(0, data);
    var httpResult = _cups.cupsStartDocument(
        CUPS_HTTP_DEFAULT, printerNamePtr, jobId, dataPtr, formatPtr, 1);
    if (httpResult == 100) {
      httpResult =
          _cups.cupsWriteRequestData(CUPS_HTTP_DEFAULT, dataPtr, data.length);
      if (httpResult == 100) {
        var status =
            _cups.cupsFinishDocument(CUPS_HTTP_DEFAULT, printerNamePtr);
        if (status == IPP_STATUS_OK) {
          result = true;
        }
      }
    }
    calloc.free(formatPtr);
    calloc.free(dataPtr);
  }
  calloc.free(CUPS_HTTP_DEFAULT);
  calloc.free(printerNamePtr);
  calloc.free(jobNamePtr);
  return result;
}

class _UserData extends ffi.Struct {
  @ffi.Int32()
  external int num_dests;
  external ffi.Pointer<ffi.Pointer<cups_dest_t>> dests;
}

class Printer {
  final String name;
  final bool isDefault;
  Printer(this.name, this.isDefault);
}

int _listPrinterCallback(
    ffi.Pointer<ffi.Void> user_data, int flags, ffi.Pointer<cups_dest_t> dest) {
  ffi.Pointer<_UserData> data = user_data.cast();
  if (flags & CUPS_DEST_FLAGS_REMOVED > 0) {
    data.ref.num_dests = _cups.cupsRemoveDest(
        dest.ref.name, dest.ref.instance, data.ref.num_dests, data.ref.dests);
  } else {
    data.ref.num_dests =
        _cups.cupsCopyDest(dest, data.ref.num_dests, data.ref.dests);
  }
  return 1;
}

List<Printer> listPrinters(int type, int mask) {
  var result = <Printer>[];
  ffi.Pointer<_UserData> user_data = calloc();
  user_data.ref.num_dests = 0;
  user_data.ref.dests = calloc();

  var cb =
      ffi.Pointer.fromFunction<cups_dest_cb_t>(_listPrinterCallback, EXCEPT);
  if (_cups.cupsEnumDests(CUPS_DEST_FLAGS_NONE, -1, ffi.nullptr, type, mask, cb,
          user_data.cast()) !=
      0) {
    int printerCount = user_data.ref.num_dests;
    for (var i = 0; i < printerCount; i++) {
      ffi.Pointer<Utf8> namePtr =
          user_data.ref.dests.value.elementAt(i).ref.name.cast();
      bool isDefault =
          user_data.ref.dests.value.elementAt(i).ref.is_default == 1;
      result.add(Printer(namePtr.toDartString(), isDefault));
    }
  }
  _cups.cupsFreeDests(user_data.ref.num_dests, user_data.ref.dests.value);
  calloc.free(user_data);
  return result;
}
