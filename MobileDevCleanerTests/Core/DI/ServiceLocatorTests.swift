import Foundation
import Testing
@testable import MobileDevCleaner

@Suite("ServiceLocator")
struct ServiceLocatorTests {
    @MainActor
    final class TestService {
        static var instanceCount = 0
        let id = UUID()

        init() {
            Self.instanceCount += 1
        }
    }

    @Test("factory returns new instance each time")
    @MainActor
    func factoryReturnsNewInstance() {
        let sl = ServiceLocator()
        sl.registerFactory(TestService.self) { TestService() }

        let instance1: TestService = sl.resolve()
        let instance2: TestService = sl.resolve()

        #expect(instance1.id != instance2.id)
    }

    @Test("lazySingleton returns same instance")
    @MainActor
    func lazySingletonReturnsSameInstance() {
        let sl = ServiceLocator()
        var creationCount = 0

        sl.registerLazySingleton(TestService.self) {
            creationCount += 1
            return TestService()
        }

        let instance1: TestService = sl.resolve()
        let instance2: TestService = sl.resolve()

        #expect(instance1.id == instance2.id)
        #expect(creationCount == 1)
    }

    @Test("lazySingleton is created lazily")
    @MainActor
    func lazySingletonCreatedLazily() {
        let sl = ServiceLocator()
        var creationCount = 0

        sl.registerLazySingleton(TestService.self) {
            creationCount += 1
            return TestService()
        }

        // Not created yet
        #expect(creationCount == 0)

        // Created on first resolve
        let _: TestService = sl.resolve()
        #expect(creationCount == 1)
    }

    @Test("singleton stores pre-created instance")
    @MainActor
    func singletonStoresPreCreatedInstance() {
        let sl = ServiceLocator()
        let instance = TestService()
        sl.registerSingleton(TestService.self, instance: instance)

        let resolved: TestService = sl.resolve()
        #expect(resolved.id == instance.id)
    }

    @Test("singleton returns same instance every time")
    @MainActor
    func singletonReturnsSameInstance() {
        let sl = ServiceLocator()
        let instance = TestService()
        sl.registerSingleton(TestService.self, instance: instance)

        let resolved1: TestService = sl.resolve()
        let resolved2: TestService = sl.resolve()

        #expect(resolved1.id == resolved2.id)
        #expect(resolved1.id == instance.id)
    }

    @Test("named registrations are separate")
    @MainActor
    func namedRegistrationsAreSeparate() {
        let sl = ServiceLocator()
        sl.registerFactory(TestService.self, name: "service1") { TestService() }
        sl.registerFactory(TestService.self, name: "service2") { TestService() }

        let service1: TestService = sl.resolve(name: "service1")
        let service2: TestService = sl.resolve(name: "service2")

        #expect(service1.id != service2.id)
    }

    @Test("isRegistered returns true for registered type")
    @MainActor
    func isRegisteredTrueForRegistered() {
        let sl = ServiceLocator()
        sl.registerFactory(TestService.self) { TestService() }

        #expect(sl.isRegistered(TestService.self) == true)
    }

    @Test("isRegistered returns false for unregistered type")
    @MainActor
    func isRegisteredFalseForUnregistered() {
        let sl = ServiceLocator()
        #expect(sl.isRegistered(TestService.self) == false)
    }

    @Test("isRegistered works with named registrations")
    @MainActor
    func isRegisteredWithNamedRegistrations() {
        let sl = ServiceLocator()
        sl.registerFactory(TestService.self, name: "custom") { TestService() }

        #expect(sl.isRegistered(TestService.self, name: "custom") == true)
        #expect(sl.isRegistered(TestService.self, name: "other") == false)
        #expect(sl.isRegistered(TestService.self) == false)
    }

    @Test("reset clears all registrations")
    @MainActor
    func resetClearsRegistrations() {
        let sl = ServiceLocator()
        sl.registerFactory(TestService.self) { TestService() }

        #expect(sl.isRegistered(TestService.self) == true)

        sl.reset()

        #expect(sl.isRegistered(TestService.self) == false)
    }

    @Test("callAsFunction resolves correctly")
    @MainActor
    func callAsFunctionResolves() {
        let sl = ServiceLocator()
        sl.registerFactory(TestService.self) { TestService() }

        let _: TestService = sl()
        #expect(sl.isRegistered(TestService.self))
    }

    @Test("callAsFunction with name parameter")
    @MainActor
    func callAsFunctionWithName() {
        let sl = ServiceLocator()
        sl.registerFactory(TestService.self, name: "custom") { TestService() }

        let _: TestService = sl(name: "custom")
        #expect(sl.isRegistered(TestService.self, name: "custom"))
    }

    @Test("mixed registration types work together")
    @MainActor
    func mixedRegistrationTypes() {
        let sl = ServiceLocator()
        let singletonInstance = TestService()

        sl.registerFactory(TestService.self, name: "factory") { TestService() }
        sl.registerLazySingleton(TestService.self, name: "lazy") { TestService() }
        sl.registerSingleton(TestService.self, name: "singleton", instance: singletonInstance)

        let factory1: TestService = sl.resolve(name: "factory")
        let factory2: TestService = sl.resolve(name: "factory")
        let lazy1: TestService = sl.resolve(name: "lazy")
        let lazy2: TestService = sl.resolve(name: "lazy")
        let singleton1: TestService = sl.resolve(name: "singleton")

        #expect(factory1.id != factory2.id)
        #expect(lazy1.id == lazy2.id)
        #expect(singleton1.id == singletonInstance.id)
    }

    @Test("each test gets fresh ServiceLocator")
    @MainActor
    func freshServiceLocatorPerTest() {
        let sl = ServiceLocator()
        sl.registerFactory(TestService.self) { TestService() }

        // This should work and not interfere with other tests
        let _: TestService = sl.resolve()
        #expect(sl.isRegistered(TestService.self))
    }
}
