import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';

import '../enums/public_key_credential_type.dart';
import '../helpers/base64.dart';
import '../models/converters/uint8list_converter.dart';
import 'assertion_response_data.dart';

part 'generated/assertion_response.g.dart';

@JsonSerializable(explicitToJson: true, anyMap: true)
class AssertionResponse {
  String id;
  @Uint8ListConverter()
  Uint8List rawId;
  PublicKeyCredentialType type;
  AssertionResponseData response;

  AssertionResponse({
    required this.rawId,
    required this.type,
    required this.response,
  }) : id = b64e(rawId);

  factory AssertionResponse.fromJson(Map<String, dynamic> json) =>
      _$AssertionResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AssertionResponseToJson(this);
}
