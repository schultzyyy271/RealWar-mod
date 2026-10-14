#import "IL2CPPBridge.h"
#import <mach-o/dyld.h>
#import <dlfcn.h>

// IL2CPP object header (16 bytes on arm64)
typedef struct Il2CppObject {
    void *klass;
    void *monitor;
} Il2CppObject;

// BigInteger struct (matches System.Numerics.BigInteger)
typedef struct {
    int32_t _sign;      // 0x00
    int32_t _pad;       // 0x04 (alignment)
    void *_bits;        // 0x08 (Il2CppArray* or NULL for small values)
} BigInteger;

// IL2CPP API types
typedef void* (*il2cpp_domain_get_t)(void);
typedef void** (*il2cpp_domain_get_assemblies_t)(void *domain, size_t *count);
typedef void* (*il2cpp_assembly_get_image_t)(void *assembly);
typedef void* (*il2cpp_class_from_name_t)(void *image, const char *ns, const char *name);
typedef void* (*il2cpp_class_get_field_from_name_t)(void *klass, const char *name);
typedef void (*il2cpp_field_static_get_value_t)(void *field, void *value);
typedef void* (*il2cpp_field_get_value_object_t)(void *field, void *obj);

// Function pointer for BigIntegerObservedValue.Add(BigInteger amount, bool saveOnSet)
// IL2CPP calling convention: instance methods have 'this' as first arg, MethodInfo* as last
typedef void (*BigIntegerObservedValue_Add_t)(void *self, BigInteger amount, uint8_t saveOnSet, void *method);

// Statics
static BOOL s_ready = NO;
static uintptr_t s_baseAddress = 0;
static uintptr_t s_slide = 0;

// Cached pointers
static void *s_instanceField = NULL;  // PersistentDataManager.Instance field
static BigIntegerObservedValue_Add_t s_addFunc = NULL;

// RVAs from dump.cs
static const uintptr_t RVA_BigIntegerObservedValue_Add = 0x27986A4;

// Offsets from dump.cs
static const size_t OFFSET_PersistentDataManager_persistentData = 0x20;
static const size_t OFFSET_PersistentData_gemsAmount = 0x28;

static uintptr_t FindUnityFramework(void) {
    for (uint32_t i = 0; i < _dyld_image_count(); i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && strstr(name, "UnityFramework")) {
            s_slide = _dyld_get_image_vmaddr_slide(i);
            return (uintptr_t)_dyld_get_image_header(i);
        }
    }
    // Fallback: try main executable (some Unity games bundle everything)
    s_slide = _dyld_get_image_vmaddr_slide(0);
    return (uintptr_t)_dyld_get_image_header(0);
}

@implementation IL2CPPBridge

+ (BOOL)setup {
    static dispatch_once_t onceToken;
    __block BOOL success = NO;
    
    dispatch_once(&onceToken, ^{
        NSLog(@"[RealWarMod] Setting up IL2CPP bridge...");
        
        // Find base address
        s_baseAddress = FindUnityFramework();
        if (!s_baseAddress) {
            NSLog(@"[RealWarMod] Failed to find UnityFramework");
            return;
        }
        NSLog(@"[RealWarMod] Base: %p, Slide: 0x%lx", (void*)s_baseAddress, s_slide);
        
        // Resolve IL2CPP API functions
        il2cpp_domain_get_t domain_get = dlsym(RTLD_DEFAULT, "il2cpp_domain_get");
        il2cpp_domain_get_assemblies_t get_assemblies = dlsym(RTLD_DEFAULT, "il2cpp_domain_get_assemblies");
        il2cpp_assembly_get_image_t get_image = dlsym(RTLD_DEFAULT, "il2cpp_assembly_get_image");
        il2cpp_class_from_name_t class_from_name = dlsym(RTLD_DEFAULT, "il2cpp_class_from_name");
        il2cpp_class_get_field_from_name_t get_field = dlsym(RTLD_DEFAULT, "il2cpp_class_get_field_from_name");
        
        if (!domain_get || !get_assemblies || !get_image || !class_from_name || !get_field) {
            NSLog(@"[RealWarMod] Failed to resolve IL2CPP APIs");
            return;
        }
        
        // Get domain and assemblies
        void *domain = domain_get();
        if (!domain) {
            NSLog(@"[RealWarMod] Failed to get domain");
            return;
        }
        
        size_t count = 0;
        void **assemblies = get_assemblies(domain, &count);
        NSLog(@"[RealWarMod] Found %zu assemblies", count);
        
        // Find PersistentDataManager class
        void *pdmClass = NULL;
        for (size_t i = 0; i < count && !pdmClass; i++) {
            void *image = get_image(assemblies[i]);
            if (!image) continue;
            pdmClass = class_from_name(image, "", "PersistentDataManager");
        }
        
        if (!pdmClass) {
            NSLog(@"[RealWarMod] Failed to find PersistentDataManager class");
            return;
        }
        NSLog(@"[RealWarMod] Found PersistentDataManager: %p", pdmClass);
        
        // Get Instance field
        s_instanceField = get_field(pdmClass, "Instance");
        if (!s_instanceField) {
            NSLog(@"[RealWarMod] Failed to find Instance field");
            return;
        }
        NSLog(@"[RealWarMod] Found Instance field: %p", s_instanceField);
        
        // Resolve Add function using RVA + slide
        s_addFunc = (BigIntegerObservedValue_Add_t)(s_baseAddress + RVA_BigIntegerObservedValue_Add);
        NSLog(@"[RealWarMod] Add function at: %p", s_addFunc);
        
        s_ready = YES;
        success = YES;
        NSLog(@"[RealWarMod] IL2CPP bridge ready!");
    });
    
    return success || s_ready;
}

+ (BOOL)isReady {
    return s_ready;
}

+ (BOOL)addGems:(int64_t)amount {
    if (!s_ready) {
        NSLog(@"[RealWarMod] Bridge not ready");
        return NO;
    }
    
    // Get static field value
    il2cpp_field_static_get_value_t static_get = dlsym(RTLD_DEFAULT, "il2cpp_field_static_get_value");
    if (!static_get) {
        NSLog(@"[RealWarMod] Failed to resolve il2cpp_field_static_get_value");
        return NO;
    }
    
    // Get PersistentDataManager.Instance
    void *instance = NULL;
    static_get(s_instanceField, &instance);
    if (!instance) {
        NSLog(@"[RealWarMod] PersistentDataManager.Instance is null");
        return NO;
    }
    
    // Get persistentData field (offset 0x20)
    void *persistentData = *(void **)((uint8_t *)instance + OFFSET_PersistentDataManager_persistentData);
    if (!persistentData) {
        NSLog(@"[RealWarMod] persistentData is null");
        return NO;
    }
    
    // Get gemsAmountBigIntegerObservedValue (offset 0x28)
    void *gemsOV = *(void **)((uint8_t *)persistentData + OFFSET_PersistentData_gemsAmount);
    if (!gemsOV) {
        NSLog(@"[RealWarMod] gemsAmountBigIntegerObservedValue is null");
        return NO;
    }
    
    NSLog(@"[RealWarMod] Adding %lld gems to ObservedValue at %p", amount, gemsOV);
    
    // Create BigInteger for the amount
    BigInteger amountBI = {
        ._sign = (int32_t)amount,
        ._pad = 0,
        ._bits = NULL  // NULL means value fits in _sign
    };
    
    // Call Add(BigInteger amount, bool saveOnSet, MethodInfo* method)
    @try {
        s_addFunc(gemsOV, amountBI, 1, NULL);
        NSLog(@"[RealWarMod] Successfully added %lld gems!", amount);
        return YES;
    } @catch (NSException *e) {
        NSLog(@"[RealWarMod] Exception calling Add: %@", e);
        return NO;
    }
}

@end
