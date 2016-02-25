// RUN: %target-parse-verify-swift

// RUN: %target-parse-verify-swift -parse -debug-generic-signatures %s > %t.dump 2>&1 
// RUN: FileCheck %s < %t.dump

class A {
  func foo() { }
}

class B : A {
  func bar() { }
}

class Other { }

func f1<T : A where T : Other>(_: T) { } // expected-error{{generic parameter 'T' cannot be a subclass of both 'A' and 'Other'}}
func f2<T : A where T : B>(_: T) { }

class GA<T> {}
class GB<T> : GA<T> {}

protocol P {}

func f3<T, U where U : GA<T>>(_: T, _: U) {}
func f4<T, U where U : GA<T>>(_: T, _: U) {}
func f5<T, U : GA<T>>(_: T, _: U) {}
func f6<U : GA<T>, T : P>(_: T, _: U) {}
func f7<U, T where U : GA<T>, T : P>(_: T, _: U) {}

func f8<T : GA<A> where T : GA<B>>(_: T) { } // expected-error{{generic parameter 'T' cannot be a subclass of both 'GA<A>' and 'GA<B>'}}

func f9<T : GA<A> where T : GB<A>>(_: T) { }
func f10<T : GB<A> where T : GA<A>>(_: T) { }

func f11<T : GA<T>>(_: T) { } // expected-error{{superclass constraint 'GA<T>' is recursive}}
func f12<T : GA<U>, U : GB<T>>(_: T, _: U) { } // expected-error{{superclass constraint 'GA<U>' is recursive}}
func f13<T : U, U : GA<T>>(_: T, _: U) { } // expected-error{{inheritance from non-protocol, non-class type 'U'}}

// rdar://problem/24730536
// Superclass constraints can be used to resolve nested types to concrete types.

protocol P3 {
  associatedtype T
}

protocol P2 {
  associatedtype T : P3
}

class C : P3 {
  typealias T = Int
}

class S : P2 {
  typealias T = C
}

extension P2 where Self.T : C {
  // CHECK: superclass_constraint.(file).P2.concreteTypeWitnessViaSuperclass1
  // CHECK: Generic signature: <Self where Self : P2, Self.T : C, Self.T : P3, Self.T.T == T>
  // CHECK: Canonical generic signature: <τ_0_0 where τ_0_0 : P2, τ_0_0.T : C, τ_0_0.T : P3, τ_0_0.T.T == Int>
  func concreteTypeWitnessViaSuperclass1(x: Self.T.T) {}
}

// CHECK: superclassConformance1
// CHECK: Requirements:
// CHECK-NEXT: T witness marker
// CHECK-NEXT: T : C [explicit @ /Users/dgregor/Projects/swift/swift/test/Generics/superclass_constraint.swift
// CHECK-NEXT: T : P3 [redundant @ /Users/dgregor/Projects/swift/swift/test/Generics/superclass_constraint.swift
// CHECK-NEXT: T[.P3].T == T [protocol]
// CHECK: Canonical generic signature for mangling: <τ_0_0 where τ_0_0 : C>
func superclassConformance1<T where T : C, T : P3>(t: T) { }

// CHECK: superclassConformance2
// CHECK: Requirements:
// CHECK-NEXT: T witness marker
// CHECK-NEXT: T : C [explicit @ /Users/dgregor/Projects/swift/swift/test/Generics/superclass_constraint.swift
// CHECK-NEXT: T : P3 [redundant @ /Users/dgregor/Projects/swift/swift/test/Generics/superclass_constraint.swift
// CHECK-NEXT: T[.P3].T == T [protocol]
// CHECK: Canonical generic signature for mangling: <τ_0_0 where τ_0_0 : C>
func superclassConformance2<T where T : C, T : P3>(t: T) { }

protocol P4 { }

class C2 : C, P4 { }

// CHECK: superclassConformance3
// CHECK: Requirements:
// CHECK-NEXT: T witness marker
// CHECK-NEXT: T : C2 [explicit @ /Users/dgregor/Projects/swift/swift/test/Generics/superclass_constraint.swift
// CHECK-NEXT: T : P4 [redundant @ /Users/dgregor/Projects/swift/swift/test/Generics/superclass_constraint.swift
// CHECK: Canonical generic signature for mangling: <τ_0_0 where τ_0_0 : C2>
func superclassConformance3<T where T : C, T : P4, T : C2>(t: T) { }