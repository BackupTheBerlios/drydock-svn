#import "JAPropertyListAccessors.h"
#import "OOMaths.h"


Vector OOVectorFromObject(id object, Vector defaultValue);
Quaternion OOQuaternionFromObject(id object, Quaternion defaultValue);

NSDictionary *OOPropertyListFromVector(Vector value);
NSDictionary *OOPropertyListFromQuaternion(Quaternion value);
