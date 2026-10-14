#import "IL2CPPBridge.h"
#import <objc/runtime.h>

// IL2CPP API function types
typedef void* (*il2cpp_domain_get_t)(void);
typedef void** (*il2cpp_domain_get_assemblies_t)(void *domain, size_t *count);
typedef void* (*il2cpp_assembly_get_image_t)(void *assembly);
typedef void* (*il2cpp_class_from_name_t)(void *image, const char *ns, const char *name);
typedef void* (*il2cpp_class_get_field_from_name_t)(void *klass, const char *name);
typedef void* (*il2cpp_field_get_value_t)(void *obj, void *field, void *value);
typedef void* (*il2cpp_field_static_get_value_t)(void *field, void *value);
typedef void* (*il2cpp_class_get_method_from_name_t)(void *klass, const char *name, int argsCount);
typedef size_t (*il2cpp_field_get_offset_t)(void *field);

// Function pointer for BigIntegerObservedValue.Add(BigInteger, bool)
// RVA: 0x27986A4
typedef void (*BigIntegerObservedValue_Add_t)(BigIntegerObservedValue *self, BigInteger amount, uint8_t saveOnSet, void *method);

// Static storage
static uintptr_t s_il2cppBase = 0;
static BOOL s_ready = NO;

// IL2CPP API pointers
static il2cpp_domain_get_t il2cpp_domain_get;
static il2cpp_domain_get_assemblies_t il2cpp_domain_get_assemblies;
static il2cpp_assembly_get_image_t il2cpp_assembly_get_image;
static il2cpp_class_from_name_t il2cpp_class_from_name;
static il2cpp_class_get_field_from_name_t il2cpp_class_get_field_from_name;
static il2cpp_field_static_get_value_t il2cpp_field_static_get_value;
static il2cpp_field_get_offset_t il2cpp_field_get_offset;

// Cached class/field pointers
static void *s_persistentDataManagerClass = NULL;
static void *s_instanceField = NULL;

// Function pointers from RVAs
static BigIntegerObservedValue_Add_t s_bigIntAdd = NULL;

static uintptr_t GetIL2CPPBase(void) {
    // Try UnityFramework first (common for Unity iOS apps)
    for (uint32_t i = 0; i < _dyld_image_count(); i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && (strstr(name, "UnityFramework") || strstr(name, "RealWar"))) {
            return (uintptr_t)_dyld_get_image_header(i);
        }
    }
    // Fallback: main executable
    return (uintptr_t)_dyld_get_image_header(0);
}

static void *ResolveRVA(uintptr_t rva) {
    if (!s_il2cppBase) return NULL;
    return (void *)(s_il2cppBase + rva);
}

@implementation IL2CPPBridge

+ (BOOL)isReady {
    return s_ready;
}

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self doInit];
    });
}

+ (void)doInit {
    // Find IL2CPP base
    s_il2cppBase = GetIL2CPPBase();
    if (!s_il2cppBase) {
        NSLog(@"[RealWarMod] Failed to find IL2CPP base");
        return;
    }
    NSLog(@"[RealWarMod] IL2CPP base: %p", (void *)s_il2cppBase);
    
    // Load IL2CPP API functions - try UnityFramework first, then main image
    void *handle = dlopen(NULL, RTLD_NOW);  // Search all loaded images
    
    il2cpp_domain_get = (il2cpp_domain_get_t)dlsym(handle, "il2cpp_domain_get");
    il2cpp_domain_get_assemblies = (il2cpp_domain_get_assemblies_t)dlsym(handle, "il2cpp_domain_get_assemblies");
    il2cpp_assembly_get_image = (il2cpp_assembly_get_image_t)dlsym(handle, "il2cpp_assembly_get_image");
    il2cpp_class_from_name = (il2cpp_class_from_name_t)dlsym(handle, "il2cpp_class_from_name");
    il2cpp_class_get_field_from_name = (il2cpp_class_get_field_from_name_t)dlsym(handle, "il2cpp_class_get_field_from_name");
    il2cpp_field_static_get_value = (il2cpp_field_static_get_value_t)dlsym(handle, "il2cpp_field_static_get_value");
    il2cpp_field_get_offset = (il2cpp_field_get_offset_t)dlsym(handle, "il2cpp_field_get_offset");
    
    if (!il2cpp_domain_get || !il2cpp_class_from_name) {
        NSLog(@"[RealWarMod] Failed to resolve IL2CPP APIs");
        return;
    }
    
    // Get domain and assemblies
    void *domain = il2cpp_domain_get();
    if (!domain) {
        NSLog(@"[RealWarMod] Failed to get IL2CPP domain");
        return;
    }
    
    size_t assemblyCount = 0;
    void **assemblies = il2cpp_domain_get_assemblies(domain, &assemblyCount);
    
    // Find Assembly-CSharp (or iterate all to find PersistentDataManager)
    for (size_t i = 0; i < assemblyCount && !s_persistentDataManagerClass; i++) {
        void *image = il2cpp_assembly_get_image(assemblies[i]);
        if (!image) continue;
        
        // Try empty namespace (global namespace)
        s_persistentDataManagerClass = il2cpp_class_from_name(image, "", "PersistentDataManager");
        if (s_persistentDataManagerClass) break;
    }
    
    if (!s_persistentDataManagerClass) {
        NSLog(@"[RealWarMod] Failed to find PersistentDataManager class");
        return;
    }
    NSLog(@"[RealWarMod] Found PersistentDataManager: %p", s_persistentDataManagerClass);
    
    // Get the Instance static field
    s_instanceField = il2cpp_class_get_field_from_name(s_persistentDataManagerClass, "Instance");
    if (!s_instanceField) {
        NSLog(@"[RealWarMod] Failed to find Instance field");
        return;
    }
    
    // Resolve function pointers from RVAs
    // BigIntegerObservedValue.Add at RVA 0x27986A4
    s_bigIntAdd = (BigIntegerObservedValue_Add_t)ResolveRVA(0x27986A4);
    
    NSLog(@"[RealWarMod] BigIntegerObservedValue.Add: %p", s_bigIntAdd);
    
    s_ready = YES;
    NSLog(@"[RealWarMod] IL2CPP bridge initialized successfully");
}

+ (PersistentDataManager *)getInstance {
    if (!s_ready || !s_instanceField) return NULL;
    
    PersistentDataManager *instance = NULL;
    il2cpp_field_static_get_value(s_instanceField, &instance);
    return instance;
}

+ (int64_t)currentGems {
    PersistentDataManager *mgr = [self getInstance];
    if (!mgr) return -1;
    
    PersistentData *data = mgr->persistentData;
    if (!data) return -1;
    
    BigIntegerObservedValue *gemsOV = data->gemsAmountBigIntegerObservedValue;
    if (!gemsOV) return -1;
    
    // BigInteger.value is at offset 0x10 in BigIntegerObservedValue (after klass/monitor)
    // For simple values (no _bits array), _sign holds the value directly
    BigInteger *bi = (BigInteger *)((uint8_t *)gemsOV + 0x10);
    
    if (bi->_bits == NULL) {
        // Small value stored directly in _sign
        return bi->_sign;
    } else {
        // Large value - read first word of _bits array
        // Il2CppArray layout: klass, monitor, bounds, max_length, then data
        uint32_t *bits = (uint32_t *)((uint8_t *)bi->_bits + 0x20);
        int64_t val = bits[0];
        if (bi->_sign < 0) val = -val;
        return val;
    }
}

+ (BOOL)addGems:(int64_t)amount {
    if (!s_ready || !s_bigIntAdd) return NO;
    
    PersistentDataManager *mgr = [self getInstance];
    if (!mgr) return NO;
    
    PersistentData *data = mgr->persistentData;
    if (!data) return NO;
    
    BigIntegerObservedValue *gemsOV = data->gemsAmountBigIntegerObservedValue;
    if (!gemsOV) return NO;
    
    // Create a BigInteger for the amount (simple case: fits in int32)
    BigInteger amountBI = {
        ._sign = (int32_t)amount,
        ._bits = NULL
    };
    
    // Call Add(BigInteger amount, bool saveOnSet)
    // saveOnSet = true to persist the change
    s_bigIntAdd(gemsOV, amountBI, 1, NULL);
    
    NSLog(@"[RealWarMod] Added %lld gems", amount);
    return YES;
}

+ (BOOL)setGems:(int64_t)value {
    int64_t current = [self currentGems];
    if (current < 0) return NO;
    
    int64_t diff = value - current;
    return [self addGems:diff];
}

@end
