import 'dart:typed_data';
import 'dart:convert';

class ReadBuffer {
  /// Read position
  int _readPos = 0;

  final Uint8List data;

  ByteData _byteData;

  /// Creates a [Buffer] of the given [size]
  ReadBuffer(int size) : data = new Uint8List(size) {
    _byteData = new ByteData.view(data.buffer);
  }

  ReadBuffer.fromUint8List(Uint8List list)
      : data = list,
        _byteData = new ByteData.view(list.buffer);

  /// Creates a [Buffer] with the given [list] as backing storage
  factory ReadBuffer.fromList(List<int> list) => ReadBuffer.fromUint8List(
      new Uint8List(list.length)..setRange(0, list.length, list));

  int get length => data.length;

  /// Returns the int at the specified [index]
  int operator [](int index) => data[index];

  /// Returns true if more data can be read from the buffer, false otherwise.
  bool get canReadMore => _readPos < data.length;

  /// Moves the read marker to the given [position]
  void seek(int position) => _readPos = position;

  /// Moves the read marker forwards by the given [numberOfBytes]
  void skip(int numberOfBytes) => _readPos += numberOfBytes;

  /// Resets the read and write positions markers to the start of
  /// the buffer.
  void resetRead() => _readPos = 0;

  void rest() => resetRead();

  /// Reads a null terminated list of ints from the buffer.
  /// Returns the list of ints from the buffer, without the terminating zero.
  List<int> get nullTerminatedList {
    List<int> s = <int>[];
    while (data[_readPos] != 0) {
      s.add(data[_readPos]);
      _readPos++;
    }
    _readPos++;

    return s;
  }

  /// Reads a null terminated string from the buffer.
  /// Returns the string, without a terminating null.
  String get nullTerminatedUtf8String => utf8.decode(nullTerminatedList);

  String nullTerminatedString(Encoding encoding) =>
      encoding.decode(nullTerminatedList);

  /// Reads a string from the buffer, terminating when the end of the
  /// buffer is reached.
  String get stringToEnd => readString(data.length - _readPos);

  /// Reads a string of the given [length] from the buffer.
  String readString(int length) {
    String s = utf8.decode(data.sublist(_readPos, _readPos + length));
    _readPos += length;
    return s;
  }

  /// Reads a length coded binary from the buffer. This is specified in the
  /// mysql docs.
  /// It will read up to nine bytes from the stream, depending on the first byte.
  /// Returns an unsigned integer.
  int readLengthCodedBinary() {
    int first = byte;
    if (first < 251) {
      return first;
    }
    switch (first) {
      case 251:
        return null;
      case 252:
        return uint16;
      case 253:
        return uint24;
      case 254:
        return uint64;
    }
    throw new ArgumentError('value is out of range');
  }

  static int measureLengthCodedBinary(int value) {
    if (value < 251) {
      return 1;
    }
    if (value < (2 << 15)) {
      return 3;
    }
    if (value < (2 << 23)) {
      return 4;
    }
    if (value < (2 << 63)) {
      return 5;
    }
    throw new ArgumentError('value is out of range');
  }

  /**
   * Returns a length coded string, read from the buffer.
   */
  String readLengthCodedString() {
    int length = readLengthCodedBinary();
    if (length == null) {
      return null;
    }
    return readString(length);
  }

  /**
   * Returns a single byte, read from the buffer.
   */
  int get byte => data[_readPos++];

  bool get hasMore => _readPos < data.length;

  /**
   * Returns a 16-bit integer, read from the buffer
   */
  int get int16 {
    int result = _byteData.getInt16(_readPos, Endian.little);
    _readPos += 2;
    return result;
  }

  /**
   * Returns a 16-bit integer, read from the buffer
   */
  int get uint16 {
    int result = _byteData.getUint16(_readPos, Endian.little);
    _readPos += 2;
    return result;
  }

  /**
   * Returns a 24-bit integer, read from the buffer.
   */
  int get uint24 =>
      data[_readPos++] + (data[_readPos++] << 8) + (data[_readPos++] << 16);

  /**
   * Returns a 32-bit integer, read from the buffer.
   */
  int get int32 {
    int val = _byteData.getInt32(_readPos, Endian.little);
    _readPos += 4;
    return val;
  }

  /**
   * Returns a 32-bit integer, read from the buffer.
   */
  int get uint32 {
    int val = _byteData.getUint32(_readPos, Endian.little);
    _readPos += 4;
    return val;
  }

  /**
   * Returns a 64-bit integer, read from the buffer.
   */
  int get int64 {
    int val = _byteData.getInt64(_readPos, Endian.little);
    _readPos += 8;
    return val;
  }

  /**
   * Returns a 64-bit integer, read from the buffer.
   */
  int get uint64 {
    int val = _byteData.getUint64(_readPos, Endian.little);
    _readPos += 8;
    return val;
  }

  /**
   * Returns a list of the given [numberOfBytes], read from the buffer.
   */
  List<int> readList(int numberOfBytes) {
    List<int> list = data.sublist(_readPos, _readPos + numberOfBytes);
    _readPos += numberOfBytes;
    return list;
  }

  double get float {
    double val = _byteData.getFloat32(_readPos, Endian.little);
    _readPos += 4;
    return val;
  }

  double get double_ {
    double val = _byteData.getFloat64(_readPos, Endian.little);
    _readPos += 8;
    return val;
  }
}
