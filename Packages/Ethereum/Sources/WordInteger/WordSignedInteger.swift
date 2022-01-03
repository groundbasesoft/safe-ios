//
//  File.swift
//  
//
//  Created by Dmitry Bespalov on 25.12.21.
//

import Foundation
import BigInt

// MARK: - Signed Integer

// Redundant conformance constraint 'Self' : 'SignedInteger'
public protocol WordSignedInteger: WordInteger, SignedInteger, FixedWidthInteger, ExpressibleByStringLiteral where Self.Magnitude: WordUnsignedInteger, Self.IntegerLiteralType == Int, Self.Words == [UInt] {
}


extension WordSignedInteger {
    public init(storage: [UInt]) {
        self.init()
        self.storage = Self.storage(truncating: storage, signed: true)
    }

    public var isPositive: Bool {
        !isNegative && nonzeroBitCount != 0
    }

    public var isNegative: Bool {
        let remainder = Self.bitWidth % Words.Element.bitWidth
        let shift: Int
        if remainder == 0 {
            shift = Words.Element.bitWidth - 1
        } else {
            shift = remainder - 1
        }
        return storage[storage.count - 1] >> shift == 1
    }

    init(big v: BigInt) {
        let m = Magnitude(big: v.magnitude)
        if v.sign == .minus {
            self.init(storage: m.twosComplement.storage)
        } else {
            self.init(storage: m.storage)
        }
    }

    func big() -> BigInt {
        BigInt(sign: isNegative ? .minus : .plus, magnitude: magnitude.big())
    }

    func unsigned() -> Magnitude {
        Magnitude(storage: storage)
    }
}

// roots
//extension WordSignedInteger {
////extension KInt: Equatable {
//    public static func == (lhs: Self, rhs: Self) -> Bool {
//        fatalError()
//    }
//}
extension WordSignedInteger {
//extension KInt: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: IntegerLiteralType) {
//        storage = []
        self.init(storage: [UInt(bitPattern: value)])
    }

//    typealias IntegerLiteralType = UInt
}
extension WordSignedInteger {
//extension KInt: CustomStringConvertible {
    public var description: String {
        big().description
    }
}
extension WordSignedInteger {
//extension KInt: Hashable {
    public func hash(into hasher: inout Hasher) {
        fatalError()
    }
}
extension WordSignedInteger {
//extension KInt1: Comparable {
    public static func < (lhs: Self, rhs: Self) -> Bool {
        switch (lhs.isNegative, rhs.isNegative) {
        case (true, true):
            return rhs.magnitude < lhs.magnitude
        case (false, false):
            return lhs.magnitude < rhs.magnitude
        case (false, true):
            return false
        case (true, false):
            return true
        }
    }
}

// extensions - level 1
extension WordSignedInteger {
//extension KInt: AdditiveArithmetic /* : Equatable */ {

    public static func - (lhs: Self, rhs: Self) -> Self {
        let c = lhs.subtractingReportingOverflow(rhs)
        precondition(!c.overflow)
        return c.partialValue
    }

    public static func + (lhs: Self, rhs: Self) -> Self {
        let c = lhs.addingReportingOverflow(rhs)
        precondition(!c.overflow)
        return c.partialValue
    }
}

extension WordSignedInteger {
//extension KInt: Strideable /* : Comparable */ {
    public func advanced(by n: Stride) -> Self {
        fatalError()
    }

    public func distance(to other: Self) -> Stride {
        fatalError()
    }

//    typealias Stride = KInt
}

extension WordSignedInteger {
//extension KInt: LosslessStringConvertible /* : CustomStringConvertible */ {
    public init?(_ description: String) {
        nil
    }
}

// extensions - level 2
extension WordSignedInteger {
//extension KInt: Numeric /* : AdditiveArithmetic, ExpressibleByIntegerLiteral */ {
//    typealias Magnitude = KUInt

    public var magnitude: Magnitude {
        if isNegative {
            let v = Magnitude(storage: storage)
            return v.twosComplement
        } else {
            return Magnitude(storage: storage)
        }
    }

    public init?<T>(exactly source: T) where T : BinaryInteger {
        nil
    }

    public static func *= (lhs: inout Self, rhs: Self) {
        fatalError()
    }

    public static func * (lhs: Self, rhs: Self) -> Self {
        fatalError()
    }

}

// non-standard, additional
extension WordSignedInteger {

    // expressible by string literal
    public init(stringLiteral value: String) {
        let v = BigInt(stringLiteral: value)
        self.init(big: v)
    }

    // expressible by extended grapheme ... literal
    public init(extendedGraphemeClusterLiteral value: String) {
        let v = BigInt(extendedGraphemeClusterLiteral: value)
        self.init(big: v)
    }

    // expressible by unicode scalar literal
    public init(unicodeScalarLiteral value: UnicodeScalar) {
        let v = BigInt(unicodeScalarLiteral: value)
        self.init(big: v)
    }
}

// extensions - level 3
extension WordSignedInteger {
//extension KInt: BinaryInteger /* : CustomStringConvertible, Hashable, Numeric, Strideable */ {
    public static func %= (lhs: inout Self, rhs: Self) {
        lhs = lhs % rhs
    }

    public static func /= (lhs: inout Self, rhs: Self) {
        lhs = lhs / rhs
    }

    public static func / (lhs: Self, rhs: Self) -> Self {
        let (partialValue, overflow) = lhs.dividedReportingOverflow(by: rhs)
        precondition(!overflow)
        return partialValue
    }

    public static func % (lhs: Self, rhs: Self) -> Self {
        let (partialValue, overflow) = lhs.remainderReportingOverflow(dividingBy: rhs)
        precondition(!overflow)
        return partialValue
    }

    public static func &= (lhs: inout Self, rhs: Self) {
        lhs.storage = zip(lhs.storage, rhs.storage).map(&)
    }

    public static func |= (lhs: inout Self, rhs: Self) {
        lhs.storage = zip(lhs.storage, rhs.storage).map(|)
    }

    public static func ^= (lhs: inout Self, rhs: Self) {
        lhs.storage = zip(lhs.storage, rhs.storage).map(^)
    }

    // implementing to avoid infinite recursion
    public prefix static func ~ (x: Self) -> Self {
        Self(storage: x.storage.map(~))
    }

    // implementing to avoid infinite recursion
    public static func << <RHS>(lhs: Self, rhs: RHS) -> Self where RHS : BinaryInteger {
        let a = lhs.big()
        let b = a << rhs
        return Self(big: b)
    }

    // implemented, otherwise infinite recursion
    public static func <<= <RHS>(lhs: inout Self, rhs: RHS) where RHS : BinaryInteger {
        lhs = lhs << rhs
    }

    // implemented, otherwise infinite recursion
    public static func >> <RHS>(lhs: Self, rhs: RHS) -> Self where RHS : BinaryInteger {
        // big int doesn't do shifts properly, we need to sign-extend the most significant bit

        let a = lhs.unsigned()
        var b = a >> rhs

        if lhs < 0 {
            b |= .max << (RHS(Self.bitWidth) - rhs)
        }

        return Self(storage: b.storage)
    }

    // implemented, otherwise infinite recursion
    public static func >>= <RHS>(lhs: inout Self, rhs: RHS) where RHS : BinaryInteger {
        lhs = lhs >> rhs
    }

//    typealias Words = [UInt]

    public var words: [UInt] {
        storage
    }

    public var trailingZeroBitCount: Int {
        var count = 0
        for (i, word) in storage.enumerated() {
            count += word.trailingZeroBitCount
            if i == storage.count - 1 && word.nonzeroBitCount == 0 {
                count -= storage.count * Words.Element.bitWidth - Self.bitWidth
            }
            if word.nonzeroBitCount != 0 {
                break
            }
        }
        return count
    }
}

// extensions - level 4

extension WordSignedInteger {
//extension KInt: SignedNumeric /* : Numeric */ {

}
extension WordSignedInteger {
//extension KInt: SignedInteger /* : BinaryInteger, SignedNumeric */ {

}
extension WordSignedInteger {
//extension KInt: FixedWidthInteger /* : BinaryInteger, LosslessStringConvertible */ {
//    public static var bitWidth: Int {
//        72
//    }

    public func addingReportingOverflow(_ rhs: Self) -> (partialValue: Self, overflow: Bool) {
        let a = big()
        let b = rhs.big()
        let c = a + b
        let partialValue = Self(big: c)
        let signFlipped = isPositive && rhs.isPositive && partialValue.isNegative ||
            isNegative && rhs.isNegative && partialValue.isPositive
        let overflow = (c.bitWidth - 1) > Self.bitWidth || signFlipped
        return (partialValue, overflow)
    }

    public func subtractingReportingOverflow(_ rhs: Self) -> (partialValue: Self, overflow: Bool) {
        let a = big()
        let b = rhs.big()
        let c = a - b
        let partialValue = Self(big: c)
        let signFlipped = isPositive && rhs.isNegative && partialValue.isNegative ||
            isNegative && isPositive && partialValue.isPositive
        let overflow = (c.bitWidth - 1) > Self.bitWidth || signFlipped
        return (partialValue, overflow)
    }

    public func multipliedReportingOverflow(by rhs: Self) -> (partialValue: Self, overflow: Bool) {
        let a = big()
        let b = rhs.big()
        let c = a * b
        let partialValue = Self(big: c)
        let signFlipped = isPositive && rhs.isPositive && partialValue.isNegative ||
            isNegative && rhs.isNegative && partialValue.isPositive
        let overflow = (c.bitWidth - 1) > Self.bitWidth || signFlipped
        return (partialValue, overflow)
    }

    public func dividedReportingOverflow(by rhs: Self) -> (partialValue: Self, overflow: Bool) {
        if rhs == 0 {
            return (self, true)
        }
        let a = big()
        let b = rhs.big()
        let (c, _) = a.quotientAndRemainder(dividingBy: b)
        let partialValue = Self(big: c)
        return (partialValue, false)
    }

    public func remainderReportingOverflow(dividingBy rhs: Self) -> (partialValue: Self, overflow: Bool) {
        if rhs == 0 {
            return (self, true)
        }
        let a = big()
        let b = rhs.big()
        let (_, c) = a.quotientAndRemainder(dividingBy: b)
        let partialValue = Self(big: c)
        return (partialValue, false)
    }

    public func dividingFullWidth(_ dividend: (high: Self, low: Magnitude)) -> (quotient: Self, remainder: Self) {
        // we must merge words in case the bitWidth is not aligned to word size.
        // we can't use the 'low' directly because the result of merge
        // will overflow the Self.
        var low = dividend.low.storage
        var high = dividend.high.magnitude
        let bitRemainder = Self.bitWidth % Words.Element.bitWidth
        if bitRemainder > 0 {
            // merge least significant portion of high with most significant
            // portion of low
            low[low.count - 1] |= high.storage[0] << bitRemainder
            // then remove the merged part from high
            high >>= bitRemainder
        }
        let magnitude = BigUInt(words: low + high.storage)
        let a = BigInt(sign: dividend.high.isNegative ? .minus : .plus, magnitude: magnitude)
        let b = big()
        let (q, r) = a.quotientAndRemainder(dividingBy: b)
        let (quotient, remainder) = (Self(big: q), Self(big: r))
        let signFlipped = dividend.high.isPositive && self.isPositive && quotient.isNegative ||
        dividend.high.isNegative && self.isNegative && quotient.isPositive

        // the BigInt's bitWidth = magnitude.bitWidth + 1 but this is inconsistent
        // with the 2's complement representation: the same value in 2's
        // complement will have 1 less bit because the sign is stored
        // in most significant bit of the integer.
        let overflow = (q.bitWidth - 1) > Self.bitWidth || signFlipped
        precondition(!overflow)
        return (quotient, remainder)
    }

    public var nonzeroBitCount: Int {
        storage.map(\.nonzeroBitCount).reduce(0, +)
    }

    public var leadingZeroBitCount: Int {
        var count = 0
        for (i, word) in storage.reversed().enumerated() {
            count += word.leadingZeroBitCount
            if i == 0 { // is last word
                count -= storage.count * Words.Element.bitWidth - Self.bitWidth
            }
            if word.nonzeroBitCount != 0 {
                break
            }
        }
        return count
    }

    public var byteSwapped: Self {
        var result: Self = 0
        for offset in stride(from: 0, to: Self.bitWidth, by: 8) {
            result |= ((self >> offset) & 0xff) << (Self.bitWidth - 8 - offset)
        }
        return result
    }

    public init(_truncatingBits value: UInt) {
//        storage = [value]
        self.init(storage: [value])
    }
}

extension WordSignedInteger {
    public init?<S: StringProtocol>(_ text: S, radix: Int = 10) {
        guard let big = BigInt(text, radix: radix) else { return nil }
        self.init(big: big)
    }

    public init<T: BinaryInteger>(truncatingIfNeeded source: T) {
        self.init(storage: [UInt](source.words))
    }
}
