#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>
#import <dlfcn.h>
#import <stdint.h>

// IL2CPP type definitions based on dump.cs analysis
// PersistentDataManager.Instance is static at class offset 0x0
// PersistentDataManager.persistentData is at instance offset 0x20
// PersistentData.gemsAmountBigIntegerObservedValue backing field at offset 0x28
// BigIntegerObservedValue.Add(BigInteger, bool) at RVA 0x27986A4
// ObservedValue<BigInteger>.SetValue(BigInteger, bool) at RVA 0x3EBB86C
// BigInteger struct: _sign at 0x0 (int), _bits at 0x8 (void*)

typedef struct {
    int32_t _sign;
    void *_bits;  // Il2CppArray* of uint32
} BigInteger;

typedef struct {
    void *klass;
    void *monitor;
    BigInteger value;  // ObservedValue<T>.value at 0x10
} BigIntegerObservedValue;

typedef struct {
    void *klass;
    void *monitor;
    uint8_t hasShownRateBox;       // 0x10
    uint8_t _pad[7];
    BigIntegerObservedValue *coinsAmountBigIntegerObservedValue;    // 0x18
    BigIntegerObservedValue *skipitsAmountBigIntegerObservedValue;  // 0x20
    BigIntegerObservedValue *gemsAmountBigIntegerObservedValue;     // 0x28
} PersistentData;

typedef struct {
    void *klass;
    void *monitor;
    void *_pad[2];
    PersistentData *persistentData;  // 0x20
} PersistentDataManager;

@interface IL2CPPBridge : NSObject

/// Returns YES if IL2CPP was successfully initialized
+ (BOOL)isReady;

/// Attempts to initialize the IL2CPP bridge. Call early (e.g., from %ctor).
+ (void)initialize;

/// Returns current gems count from game state, or -1 if unavailable
+ (int64_t)currentGems;

/// Adds gems to the game state. Returns YES on success.
+ (BOOL)addGems:(int64_t)amount;

/// Sets gems to exact value. Returns YES on success.
+ (BOOL)setGems:(int64_t)value;

@end
