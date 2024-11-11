// Generated by the protocol buffer compiler.  DO NOT EDIT!
// NO CHECKED-IN PROTOBUF GENCODE
// clang-format off
// source: messages-ethereum.proto

// This CPP symbol can be defined to use imports that match up to the framework
// imports needed when using CocoaPods.
#if !defined(GPB_USE_PROTOBUF_FRAMEWORK_IMPORTS)
 #define GPB_USE_PROTOBUF_FRAMEWORK_IMPORTS 0
#endif

#if GPB_USE_PROTOBUF_FRAMEWORK_IMPORTS
 #import <Protobuf/GPBProtocolBuffers.h>
#else
 #import "GPBProtocolBuffers.h"
#endif

#if GOOGLE_PROTOBUF_OBJC_VERSION < 30007
#error This file was generated by a newer version of protoc which is incompatible with your Protocol Buffer library sources.
#endif
#if 30007 < GOOGLE_PROTOBUF_OBJC_MIN_SUPPORTED_VERSION
#error This file was generated by an older version of protoc which is incompatible with your Protocol Buffer library sources.
#endif

#import "MessagesCommon.pbobjc.h"
#import "MessagesEthereumDefinitions.pbobjc.h"
// @@protoc_insertion_point(imports)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

CF_EXTERN_C_BEGIN

@class EthereumSignTxEIP1559_EthereumAccessList;

NS_ASSUME_NONNULL_BEGIN

#pragma mark - MessagesEthereumRoot

/**
 * Exposes the extension registry for this file.
 *
 * The base class provides:
 * @code
 *   + (GPBExtensionRegistry *)extensionRegistry;
 * @endcode
 * which is a @c GPBExtensionRegistry that includes all the extensions defined by
 * this file and all files that it depends on.
 **/
GPB_FINAL @interface MessagesEthereumRoot : GPBRootObject
@end

#pragma mark - EthereumGetPublicKey

typedef GPB_ENUM(EthereumGetPublicKey_FieldNumber) {
  EthereumGetPublicKey_FieldNumber_AddressNArray = 1,
  EthereumGetPublicKey_FieldNumber_ShowDisplay = 2,
};

/**
 * *
 * Request: Ask device for public key corresponding to address_n path
 * \@start
 * \@next EthereumPublicKey
 * \@next Failure
 **/
GPB_FINAL @interface EthereumGetPublicKey : GPBMessage

/** BIP-32 path to derive the key from master node */
@property(nonatomic, readwrite, strong, null_resettable) GPBUInt32Array *addressNArray;
/** The number of items in @c addressNArray without causing the container to be created. */
@property(nonatomic, readonly) NSUInteger addressNArray_Count;

/** optionally show on display before sending the result */
@property(nonatomic, readwrite) BOOL showDisplay;
@property(nonatomic, readwrite) BOOL hasShowDisplay;

@end

#pragma mark - EthereumPublicKey

typedef GPB_ENUM(EthereumPublicKey_FieldNumber) {
  EthereumPublicKey_FieldNumber_Node = 1,
  EthereumPublicKey_FieldNumber_Xpub = 2,
};

/**
 * *
 * Response: Contains public key derived from device private seed
 * \@end
 **/
GPB_FINAL @interface EthereumPublicKey : GPBMessage

/** BIP32 public node */
@property(nonatomic, readwrite, strong, null_resettable) HDNodeType *node;
/** Test to see if @c node has been set. */
@property(nonatomic, readwrite) BOOL hasNode;

/** serialized form of public node */
@property(nonatomic, readwrite, copy, null_resettable) NSString *xpub;
/** Test to see if @c xpub has been set. */
@property(nonatomic, readwrite) BOOL hasXpub;

@end

#pragma mark - EthereumGetAddress

typedef GPB_ENUM(EthereumGetAddress_FieldNumber) {
  EthereumGetAddress_FieldNumber_AddressNArray = 1,
  EthereumGetAddress_FieldNumber_ShowDisplay = 2,
  EthereumGetAddress_FieldNumber_EncodedNetwork = 3,
};

/**
 * *
 * Request: Ask device for Ethereum address corresponding to address_n path
 * \@start
 * \@next EthereumAddress
 * \@next Failure
 **/
GPB_FINAL @interface EthereumGetAddress : GPBMessage

/** BIP-32 path to derive the key from master node */
@property(nonatomic, readwrite, strong, null_resettable) GPBUInt32Array *addressNArray;
/** The number of items in @c addressNArray without causing the container to be created. */
@property(nonatomic, readonly) NSUInteger addressNArray_Count;

/** optionally show on display before sending the result */
@property(nonatomic, readwrite) BOOL showDisplay;
@property(nonatomic, readwrite) BOOL hasShowDisplay;

/** encoded Ethereum network, see ethereum-definitions.md for details */
@property(nonatomic, readwrite, copy, null_resettable) NSData *encodedNetwork;
/** Test to see if @c encodedNetwork has been set. */
@property(nonatomic, readwrite) BOOL hasEncodedNetwork;

@end

#pragma mark - EthereumAddress

typedef GPB_ENUM(EthereumAddress_FieldNumber) {
  EthereumAddress_FieldNumber_OldAddress = 1,
  EthereumAddress_FieldNumber_Address = 2,
};

/**
 * *
 * Response: Contains an Ethereum address derived from device private seed
 * \@end
 **/
GPB_FINAL @interface EthereumAddress : GPBMessage

/** trezor <1.8.0, <2.1.0 - raw bytes of Ethereum address */
@property(nonatomic, readwrite, copy, null_resettable) NSData *oldAddress GPB_DEPRECATED_MSG("hw.trezor.messages.ethereum.EthereumAddress._old_address is deprecated (see messages-ethereum.proto).");
/** Test to see if @c oldAddress has been set. */
@property(nonatomic, readwrite) BOOL hasOldAddress GPB_DEPRECATED_MSG("hw.trezor.messages.ethereum.EthereumAddress._old_address is deprecated (see messages-ethereum.proto).");

/** Ethereum address as hex-encoded string */
@property(nonatomic, readwrite, copy, null_resettable) NSString *address;
/** Test to see if @c address has been set. */
@property(nonatomic, readwrite) BOOL hasAddress;

@end

#pragma mark - EthereumSignTx

typedef GPB_ENUM(EthereumSignTx_FieldNumber) {
  EthereumSignTx_FieldNumber_AddressNArray = 1,
  EthereumSignTx_FieldNumber_Nonce = 2,
  EthereumSignTx_FieldNumber_GasPrice = 3,
  EthereumSignTx_FieldNumber_GasLimit = 4,
  EthereumSignTx_FieldNumber_Value = 6,
  EthereumSignTx_FieldNumber_DataInitialChunk = 7,
  EthereumSignTx_FieldNumber_DataLength = 8,
  EthereumSignTx_FieldNumber_ChainId = 9,
  EthereumSignTx_FieldNumber_TxType = 10,
  EthereumSignTx_FieldNumber_To = 11,
  EthereumSignTx_FieldNumber_Definitions = 12,
};

/**
 * *
 * Request: Ask device to sign transaction
 * gas_price, gas_limit and chain_id must be provided and non-zero.
 * All other fields are optional and default to value `0` if missing.
 * Note: the first at most 1024 bytes of data MUST be transmitted as part of this message.
 * \@start
 * \@next EthereumTxRequest
 * \@next Failure
 **/
GPB_FINAL @interface EthereumSignTx : GPBMessage

/** BIP-32 path to derive the key from master node */
@property(nonatomic, readwrite, strong, null_resettable) GPBUInt32Array *addressNArray;
/** The number of items in @c addressNArray without causing the container to be created. */
@property(nonatomic, readonly) NSUInteger addressNArray_Count;

/** <=256 bit unsigned big endian */
@property(nonatomic, readwrite, copy, null_resettable) NSData *nonce;
/** Test to see if @c nonce has been set. */
@property(nonatomic, readwrite) BOOL hasNonce;

/** <=256 bit unsigned big endian (in wei) */
@property(nonatomic, readwrite, copy, null_resettable) NSData *gasPrice;
/** Test to see if @c gasPrice has been set. */
@property(nonatomic, readwrite) BOOL hasGasPrice;

/** <=256 bit unsigned big endian */
@property(nonatomic, readwrite, copy, null_resettable) NSData *gasLimit;
/** Test to see if @c gasLimit has been set. */
@property(nonatomic, readwrite) BOOL hasGasLimit;

/** recipient address */
@property(nonatomic, readwrite, copy, null_resettable) NSString *to;
/** Test to see if @c to has been set. */
@property(nonatomic, readwrite) BOOL hasTo;

/** <=256 bit unsigned big endian (in wei) */
@property(nonatomic, readwrite, copy, null_resettable) NSData *value;
/** Test to see if @c value has been set. */
@property(nonatomic, readwrite) BOOL hasValue;

/** The initial data chunk (<= 1024 bytes) */
@property(nonatomic, readwrite, copy, null_resettable) NSData *dataInitialChunk;
/** Test to see if @c dataInitialChunk has been set. */
@property(nonatomic, readwrite) BOOL hasDataInitialChunk;

/** Length of transaction payload */
@property(nonatomic, readwrite) uint32_t dataLength;
@property(nonatomic, readwrite) BOOL hasDataLength;

/** Chain Id for EIP 155 */
@property(nonatomic, readwrite) uint64_t chainId;
@property(nonatomic, readwrite) BOOL hasChainId;

/** Used for Wanchain */
@property(nonatomic, readwrite) uint32_t txType;
@property(nonatomic, readwrite) BOOL hasTxType;

/** network and/or token definitions for tx */
@property(nonatomic, readwrite, strong, null_resettable) EthereumDefinitions *definitions;
/** Test to see if @c definitions has been set. */
@property(nonatomic, readwrite) BOOL hasDefinitions;

@end

#pragma mark - EthereumSignTxEIP1559

typedef GPB_ENUM(EthereumSignTxEIP1559_FieldNumber) {
  EthereumSignTxEIP1559_FieldNumber_AddressNArray = 1,
  EthereumSignTxEIP1559_FieldNumber_Nonce = 2,
  EthereumSignTxEIP1559_FieldNumber_MaxGasFee = 3,
  EthereumSignTxEIP1559_FieldNumber_MaxPriorityFee = 4,
  EthereumSignTxEIP1559_FieldNumber_GasLimit = 5,
  EthereumSignTxEIP1559_FieldNumber_To = 6,
  EthereumSignTxEIP1559_FieldNumber_Value = 7,
  EthereumSignTxEIP1559_FieldNumber_DataInitialChunk = 8,
  EthereumSignTxEIP1559_FieldNumber_DataLength = 9,
  EthereumSignTxEIP1559_FieldNumber_ChainId = 10,
  EthereumSignTxEIP1559_FieldNumber_AccessListArray = 11,
  EthereumSignTxEIP1559_FieldNumber_Definitions = 12,
};

/**
 * *
 * Request: Ask device to sign EIP1559 transaction
 * Note: the first at most 1024 bytes of data MUST be transmitted as part of this message.
 * \@start
 * \@next EthereumTxRequest
 * \@next Failure
 **/
GPB_FINAL @interface EthereumSignTxEIP1559 : GPBMessage

/** BIP-32 path to derive the key from master node */
@property(nonatomic, readwrite, strong, null_resettable) GPBUInt32Array *addressNArray;
/** The number of items in @c addressNArray without causing the container to be created. */
@property(nonatomic, readonly) NSUInteger addressNArray_Count;

/** <=256 bit unsigned big endian */
@property(nonatomic, readwrite, copy, null_resettable) NSData *nonce;
/** Test to see if @c nonce has been set. */
@property(nonatomic, readwrite) BOOL hasNonce;

/** <=256 bit unsigned big endian (in wei) */
@property(nonatomic, readwrite, copy, null_resettable) NSData *maxGasFee;
/** Test to see if @c maxGasFee has been set. */
@property(nonatomic, readwrite) BOOL hasMaxGasFee;

/** <=256 bit unsigned big endian (in wei) */
@property(nonatomic, readwrite, copy, null_resettable) NSData *maxPriorityFee;
/** Test to see if @c maxPriorityFee has been set. */
@property(nonatomic, readwrite) BOOL hasMaxPriorityFee;

/** <=256 bit unsigned big endian */
@property(nonatomic, readwrite, copy, null_resettable) NSData *gasLimit;
/** Test to see if @c gasLimit has been set. */
@property(nonatomic, readwrite) BOOL hasGasLimit;

/** recipient address */
@property(nonatomic, readwrite, copy, null_resettable) NSString *to;
/** Test to see if @c to has been set. */
@property(nonatomic, readwrite) BOOL hasTo;

/** <=256 bit unsigned big endian (in wei) */
@property(nonatomic, readwrite, copy, null_resettable) NSData *value;
/** Test to see if @c value has been set. */
@property(nonatomic, readwrite) BOOL hasValue;

/** The initial data chunk (<= 1024 bytes) */
@property(nonatomic, readwrite, copy, null_resettable) NSData *dataInitialChunk;
/** Test to see if @c dataInitialChunk has been set. */
@property(nonatomic, readwrite) BOOL hasDataInitialChunk;

/** Length of transaction payload */
@property(nonatomic, readwrite) uint32_t dataLength;
@property(nonatomic, readwrite) BOOL hasDataLength;

/** Chain Id for EIP 155 */
@property(nonatomic, readwrite) uint64_t chainId;
@property(nonatomic, readwrite) BOOL hasChainId;

/** Access List */
@property(nonatomic, readwrite, strong, null_resettable) NSMutableArray<EthereumSignTxEIP1559_EthereumAccessList*> *accessListArray;
/** The number of items in @c accessListArray without causing the container to be created. */
@property(nonatomic, readonly) NSUInteger accessListArray_Count;

/** network and/or token definitions for tx */
@property(nonatomic, readwrite, strong, null_resettable) EthereumDefinitions *definitions;
/** Test to see if @c definitions has been set. */
@property(nonatomic, readwrite) BOOL hasDefinitions;

@end

#pragma mark - EthereumSignTxEIP1559_EthereumAccessList

typedef GPB_ENUM(EthereumSignTxEIP1559_EthereumAccessList_FieldNumber) {
  EthereumSignTxEIP1559_EthereumAccessList_FieldNumber_Address = 1,
  EthereumSignTxEIP1559_EthereumAccessList_FieldNumber_StorageKeysArray = 2,
};

GPB_FINAL @interface EthereumSignTxEIP1559_EthereumAccessList : GPBMessage

@property(nonatomic, readwrite, copy, null_resettable) NSString *address;
/** Test to see if @c address has been set. */
@property(nonatomic, readwrite) BOOL hasAddress;

@property(nonatomic, readwrite, strong, null_resettable) NSMutableArray<NSData*> *storageKeysArray;
/** The number of items in @c storageKeysArray without causing the container to be created. */
@property(nonatomic, readonly) NSUInteger storageKeysArray_Count;

@end

#pragma mark - EthereumTxRequest

typedef GPB_ENUM(EthereumTxRequest_FieldNumber) {
  EthereumTxRequest_FieldNumber_DataLength = 1,
  EthereumTxRequest_FieldNumber_SignatureV = 2,
  EthereumTxRequest_FieldNumber_SignatureR = 3,
  EthereumTxRequest_FieldNumber_SignatureS = 4,
};

/**
 * *
 * Response: Device asks for more data from transaction payload, or returns the signature.
 * If data_length is set, device awaits that many more bytes of payload.
 * Otherwise, the signature_* fields contain the computed transaction signature. All three fields will be present.
 * \@end
 * \@next EthereumTxAck
 **/
GPB_FINAL @interface EthereumTxRequest : GPBMessage

/** Number of bytes being requested (<= 1024) */
@property(nonatomic, readwrite) uint32_t dataLength;
@property(nonatomic, readwrite) BOOL hasDataLength;

/** Computed signature (recovery parameter, limited to 27 or 28) */
@property(nonatomic, readwrite) uint32_t signatureV;
@property(nonatomic, readwrite) BOOL hasSignatureV;

/** Computed signature R component (256 bit) */
@property(nonatomic, readwrite, copy, null_resettable) NSData *signatureR;
/** Test to see if @c signatureR has been set. */
@property(nonatomic, readwrite) BOOL hasSignatureR;

/** Computed signature S component (256 bit) */
@property(nonatomic, readwrite, copy, null_resettable) NSData *signatureS;
/** Test to see if @c signatureS has been set. */
@property(nonatomic, readwrite) BOOL hasSignatureS;

@end

#pragma mark - EthereumTxAck

typedef GPB_ENUM(EthereumTxAck_FieldNumber) {
  EthereumTxAck_FieldNumber_DataChunk = 1,
};

/**
 * *
 * Request: Transaction payload data.
 * \@next EthereumTxRequest
 **/
GPB_FINAL @interface EthereumTxAck : GPBMessage

/** Bytes from transaction payload (<= 1024 bytes) */
@property(nonatomic, readwrite, copy, null_resettable) NSData *dataChunk;
/** Test to see if @c dataChunk has been set. */
@property(nonatomic, readwrite) BOOL hasDataChunk;

@end

#pragma mark - EthereumSignMessage

typedef GPB_ENUM(EthereumSignMessage_FieldNumber) {
  EthereumSignMessage_FieldNumber_AddressNArray = 1,
  EthereumSignMessage_FieldNumber_Message = 2,
  EthereumSignMessage_FieldNumber_EncodedNetwork = 3,
};

/**
 * *
 * Request: Ask device to sign message
 * \@start
 * \@next EthereumMessageSignature
 * \@next Failure
 **/
GPB_FINAL @interface EthereumSignMessage : GPBMessage

/** BIP-32 path to derive the key from master node */
@property(nonatomic, readwrite, strong, null_resettable) GPBUInt32Array *addressNArray;
/** The number of items in @c addressNArray without causing the container to be created. */
@property(nonatomic, readonly) NSUInteger addressNArray_Count;

/** message to be signed */
@property(nonatomic, readwrite, copy, null_resettable) NSData *message;
/** Test to see if @c message has been set. */
@property(nonatomic, readwrite) BOOL hasMessage;

/** encoded Ethereum network, see ethereum-definitions.md for details */
@property(nonatomic, readwrite, copy, null_resettable) NSData *encodedNetwork;
/** Test to see if @c encodedNetwork has been set. */
@property(nonatomic, readwrite) BOOL hasEncodedNetwork;

@end

#pragma mark - EthereumMessageSignature

typedef GPB_ENUM(EthereumMessageSignature_FieldNumber) {
  EthereumMessageSignature_FieldNumber_Signature = 2,
  EthereumMessageSignature_FieldNumber_Address = 3,
};

/**
 * *
 * Response: Signed message
 * \@end
 **/
GPB_FINAL @interface EthereumMessageSignature : GPBMessage

/** signature of the message */
@property(nonatomic, readwrite, copy, null_resettable) NSData *signature;
/** Test to see if @c signature has been set. */
@property(nonatomic, readwrite) BOOL hasSignature;

/** address used to sign the message */
@property(nonatomic, readwrite, copy, null_resettable) NSString *address;
/** Test to see if @c address has been set. */
@property(nonatomic, readwrite) BOOL hasAddress;

@end

#pragma mark - EthereumVerifyMessage

typedef GPB_ENUM(EthereumVerifyMessage_FieldNumber) {
  EthereumVerifyMessage_FieldNumber_Signature = 2,
  EthereumVerifyMessage_FieldNumber_Message = 3,
  EthereumVerifyMessage_FieldNumber_Address = 4,
};

/**
 * *
 * Request: Ask device to verify message
 * \@start
 * \@next Success
 * \@next Failure
 **/
GPB_FINAL @interface EthereumVerifyMessage : GPBMessage

/** signature to verify */
@property(nonatomic, readwrite, copy, null_resettable) NSData *signature;
/** Test to see if @c signature has been set. */
@property(nonatomic, readwrite) BOOL hasSignature;

/** message to verify */
@property(nonatomic, readwrite, copy, null_resettable) NSData *message;
/** Test to see if @c message has been set. */
@property(nonatomic, readwrite) BOOL hasMessage;

/** address to verify */
@property(nonatomic, readwrite, copy, null_resettable) NSString *address;
/** Test to see if @c address has been set. */
@property(nonatomic, readwrite) BOOL hasAddress;

@end

#pragma mark - EthereumSignTypedHash

typedef GPB_ENUM(EthereumSignTypedHash_FieldNumber) {
  EthereumSignTypedHash_FieldNumber_AddressNArray = 1,
  EthereumSignTypedHash_FieldNumber_DomainSeparatorHash = 2,
  EthereumSignTypedHash_FieldNumber_MessageHash = 3,
  EthereumSignTypedHash_FieldNumber_EncodedNetwork = 4,
};

/**
 * *
 * Request: Ask device to sign hash of typed data
 * \@start
 * \@next EthereumTypedDataSignature
 * \@next Failure
 **/
GPB_FINAL @interface EthereumSignTypedHash : GPBMessage

/** BIP-32 path to derive the key from master node */
@property(nonatomic, readwrite, strong, null_resettable) GPBUInt32Array *addressNArray;
/** The number of items in @c addressNArray without causing the container to be created. */
@property(nonatomic, readonly) NSUInteger addressNArray_Count;

/** Hash of domainSeparator of typed data to be signed */
@property(nonatomic, readwrite, copy, null_resettable) NSData *domainSeparatorHash;
/** Test to see if @c domainSeparatorHash has been set. */
@property(nonatomic, readwrite) BOOL hasDomainSeparatorHash;

/** Hash of the data of typed data to be signed (empty if domain-only data) */
@property(nonatomic, readwrite, copy, null_resettable) NSData *messageHash;
/** Test to see if @c messageHash has been set. */
@property(nonatomic, readwrite) BOOL hasMessageHash;

/** encoded Ethereum network, see ethereum-definitions.md for details */
@property(nonatomic, readwrite, copy, null_resettable) NSData *encodedNetwork;
/** Test to see if @c encodedNetwork has been set. */
@property(nonatomic, readwrite) BOOL hasEncodedNetwork;

@end

#pragma mark - EthereumTypedDataSignature

typedef GPB_ENUM(EthereumTypedDataSignature_FieldNumber) {
  EthereumTypedDataSignature_FieldNumber_Signature = 1,
  EthereumTypedDataSignature_FieldNumber_Address = 2,
};

/**
 * *
 * Response: Signed typed data
 * \@end
 **/
GPB_FINAL @interface EthereumTypedDataSignature : GPBMessage

/** signature of the typed data */
@property(nonatomic, readwrite, copy, null_resettable) NSData *signature;
/** Test to see if @c signature has been set. */
@property(nonatomic, readwrite) BOOL hasSignature;

/** address used to sign the typed data */
@property(nonatomic, readwrite, copy, null_resettable) NSString *address;
/** Test to see if @c address has been set. */
@property(nonatomic, readwrite) BOOL hasAddress;

@end

NS_ASSUME_NONNULL_END

CF_EXTERN_C_END

#pragma clang diagnostic pop

// @@protoc_insertion_point(global_scope)

// clang-format on
