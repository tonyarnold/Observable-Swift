//
//  ObservableTests.swift
//  Observable-SwiftTests
//
//  Created by Leszek Ślażyński on 20/06/14.
//  Copyright (c) 2014 Leszek Ślażyński. All rights reserved.
//

import XCTest

import Observable

class ObservableTests: XCTestCase {
    
    func testPairObservable() {
        
        var (first, last) = (Observable("John"), Observable("Smith"))
        
        let either = first & last
        
        let getFull = { "\($0 as String) \($1 as String)" }
        var full = getFull(first, last)
        
        either.afterChange += { full = getFull($0, $1) }
        
        last <- "Snow"
        XCTAssertEqual(full, "John Snow", "Should update when first element changes")
        
        first <- "Ramsey"
        XCTAssertEqual(full, "Ramsey Snow", "Should update when second element changes")
        
        last <- "Bolton"
        XCTAssertEqual(full, "Ramsey Bolton", "Should update when first element changes again")

    }
    
    func testTripleObserver() {
        var (title, first, last) = (Observable("Mr."), Observable("John"), Observable("Smith"))
        var either3 = title & first & last
        
        let getFull = { "\($0 as String) \($1 as String) \($2 as String)" }
        var full = getFull(title, first, last)

        either3.afterChange += { full = getFull($0.0, $0.1, $1) }
        
        last <- "Snow"
        title <- "Bastard"
        XCTAssertEqual(full, "Bastard John Snow", "Should update when first element changes")
    }
    
    func testObservablePair() {
        var both = Observable(("John", "Smith"))
        
        let getFull = { (x : (String, String)) in "\(x.0 as String) \(x.1 as String)" }
        var full = getFull(both)

        both.afterChange += { full = getFull($0) }
        
        // fortunately this calls a setter (as a tuples are value types)
        both.value.1 = "Snow"
        XCTAssertEqual(full, getFull(both), "Should update when one element changes")

        both <- ("Ramsey", "Bolton")
        XCTAssertEqual(full, "Ramsey Bolton", "Should update when whole tuple changes")
    }
    
    func testObservableTriple() {
        var either3 = Observable(("Mr.", "John", "Smith"))
        
        let getFull = { (x: (String, String, String)) in "\(x.0) \(x.1) \(x.2)" }
        var full = getFull(either3)
        
        either3.afterChange += { full = getFull($0) }
        
        either3.value.2 = "Snow"
        either3.value.0 = "Bastard"
        XCTAssertEqual(full, "Bastard John Snow", "Should update when first element changes")
    }
    
    func testObservableStruct() {
        struct Person {
            var first: String
            var last: String
        }
        
        var person = Observable(Person(first: "John", last: "Smith"))
        let getFull = { (x: Person) in "\(x.first) \(x.last)" }
        var full = getFull(person)
        
        person.afterChange += { full = getFull($0) }
        
        // fortunately this calls a setter (as a structs are value types)
        person.value.last = "Snow"
        
        XCTAssertEqual(full, "John Snow", "Should update when field changes")
    }
    
    func testRemove() {
        var x = Observable(0)
        var y = 0
        
        let observer = x.afterChange += { (_,_) in y += 1 }
        
        for i in 0..5 { x <- i }
        
        x.afterChange -= observer
        
        for i in 0..5 { x <- i }
        XCTAssertEqual(y, 5, "Should not update after removed")
    }
    
    func testMultipleTimes() {
        var x = Observable(0)
        var y = 0
        x.afterChange.add(x.afterChange += { (_,_) in y += 1 })
        
        for i in 0..10 { x <- i }
        
        XCTAssertEqual(y, 20, "Should be called twice every update")
    }
    
    func testRemoveMultiple() {
        var x = Observable(0)
        var y = 0
        let obs = x.afterChange.add(x.afterChange += { (_,_) in y += 1 })
        
        for i in 0..10 { x <- i }
        XCTAssertEqual(y, 20, "Should be called twice every update")

        x.afterChange -= obs // this should remove once only...
        
        for i in 0..10 { x <- i }
        XCTAssertEqual(y, 30, "Should be called once after removal")
        
        x.afterChange -= obs // this should remove the second ocurrence
        
        for i in 0..10 { x <- i }
        XCTAssertEqual(y, 30, "Should not be called after removal")
    }
    
    func testOwnership() {
        var x = Observable(0)
        var y = 0
        
        for _ in 0..1 {
            let owner = NSObject()
            x.afterChange.add(owner: owner) { y = $0 }
            x <- 12
            x <- 42
        }
        x <- -1
        
        XCTAssertEqual(y, 42, "Should not update after owner is deallocated")
    }
    
    func testReferenceOwnership() {
        var x = Observable(0)
        
        var y = 0
        
        for _ in 0..1 {
            let xr = reference(&x)
            xr.afterChange += { (_,_) in y += 1 }
            for i in 0..5 { x <- i }
        }
        
        for i in 0..5 { x <- i }
        
        XCTAssertEqual(y, 5, "Should increment only when reference is alive")
        
    }

    func testReferenceLifetime() {
        var x = Observable(0)
        var y = 0

        var xr = reference(&x)
        xr.afterChange += { (_,_) in y += 1 }
        

        for i in 0..5 { x <- i }
        
        var z = x
        
        x = Observable(0)
        
        for i in 0..5 { x <- i }

        for i in 0..2 { z <- i }

        XCTAssertEqual(y, 7, "Should increment for refered object or a copy")
    }

    
}
