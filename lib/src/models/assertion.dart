import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';

import '../models/converters/uint8list_converter.dart';

part 'generated/assertion.g.dart';

/// An assertion to prove that the [selectedCredentialId] is owned by
/// the user who is using the authenticator. The auth server can verify
/// this assertion using the [authenticatorData] and the [signature]
/// that is returned.
@JsonSerializable(converters: [Uint8ListConverter()])
class Assertion {
  @JsonKey(name: 'selected_credential_id')
  Uint8List selectedCredentialId;
  @JsonKey(name: 'authenticator_data')
  Uint8List authenticatorData;
  Uint8List signature;
  @JsonKey(name: 'selected_credential_user_handle')
  Uint8List selectedCredentialUserHandle;

  Assertion({
    required this.selectedCredentialId,
    required this.authenticatorData,
    required this.signature,
    required this.selectedCredentialUserHandle,
  });

  factory Assertion.fromJson(Map<String, dynamic> json) =>
      _$AssertionFromJson(json);

  Map<String, dynamic> toJson() => _$AssertionToJson(this);
}
