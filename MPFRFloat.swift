//
// M P F R F L O A T . S W I F T
//
// MPFRFloat.swift last edited on Sun Apr  5 16:43:19 2026
//
// Arbitrary Precision Basic Statistics for one or more
// files of one or more CSV columns. This version uses
// MPFR and GMP libraries for calculations.
//

import Foundation
import CMPFR

@_silgen_name("mpfr_to_string")
func mpfr_to_string(
    _ val: UnsafeMutablePointer<__mpfr_struct>,
    _ digits: Int32
) -> UnsafeMutablePointer<CChar>!

final class MPFRFloat: Comparable {

    private var value = mpfr_t()

    static var defaultPrecision: mpfr_prec_t = 256

    init() {
        mpfr_init2(&value, Self.defaultPrecision)
        mpfr_set_d(&value, 0.0, MPFR_RNDN)
    }

    init(_ str: String) {
        mpfr_init2(&value, Self.defaultPrecision)
        _ = str.withCString {
            mpfr_set_str(&value, $0, 10, MPFR_RNDN)
        }
    }

    init(copy other: MPFRFloat) {
        mpfr_init2(&value, mpfr_get_prec(&other.value))
        mpfr_set(&value, &other.value, MPFR_RNDN)
    }

    init(precision: mpfr_prec_t) {
        mpfr_init2(&value, precision)
    }

    deinit {
        mpfr_clear(&value)
    }

    // MARK: Comparable

    static func < (lhs: MPFRFloat, rhs: MPFRFloat) -> Bool {
        mpfr_less_p(&lhs.value, &rhs.value) != 0
    }

    static func == (lhs: MPFRFloat, rhs: MPFRFloat) -> Bool {
        mpfr_equal_p(&lhs.value, &rhs.value) != 0
    }

    // MARK: Operators

    static func + (lhs: MPFRFloat, rhs: MPFRFloat) -> MPFRFloat {
        let r = MPFRFloat(precision: mpfr_get_prec(&lhs.value))
        mpfr_add(&r.value, &lhs.value, &rhs.value, MPFR_RNDN)
        return r
    }

    static func - (lhs: MPFRFloat, rhs: MPFRFloat) -> MPFRFloat {
        let r = MPFRFloat(precision: mpfr_get_prec(&lhs.value))
        mpfr_sub(&r.value, &lhs.value, &rhs.value, MPFR_RNDN)
        return r
    }

    static func * (lhs: MPFRFloat, rhs: MPFRFloat) -> MPFRFloat {
        let r = MPFRFloat(precision: mpfr_get_prec(&lhs.value))
        mpfr_mul(&r.value, &lhs.value, &rhs.value, MPFR_RNDN)
        return r
    }

    static func / (lhs: MPFRFloat, rhs: MPFRFloat) -> MPFRFloat {
        let r = MPFRFloat(precision: mpfr_get_prec(&lhs.value))
        mpfr_div(&r.value, &lhs.value, &rhs.value, MPFR_RNDN)
        return r
    }

    private func withCopy(_ body: (UnsafeMutablePointer<mpfr_t>) -> Void) {

        var temp = mpfr_t()
        mpfr_init2(&temp, mpfr_get_prec(&value))
        mpfr_set(&temp, &value, MPFR_RNDN)

        body(&temp)

        mpfr_clear(&temp)
    }

    func sqrt() -> MPFRFloat {
        let r = MPFRFloat(precision: mpfr_get_prec(&value))
        mpfr_sqrt(&r.value, &value, MPFR_RNDN)
        return r
    }

    func toString(digits: Int32) -> String {

        let cstr = mpfr_to_string(&value, digits)

        defer {
            free(cstr)      // Free the C string buffer allocated by mpfr_to_string.
        }

        return String(cString: cstr!)
    }

    func add(_ other: MPFRFloat) {
        withCopy { temp in
            mpfr_add(&value, temp, &other.value, MPFR_RNDN)
        }
    }

    func divideByUInt(_ n: UInt) {
        withCopy { temp in
            mpfr_div_ui(&value, temp, n, MPFR_RNDN)
        }
    }

    func set(_ other: MPFRFloat) {
        mpfr_set(&value, &other.value, MPFR_RNDN)
    }
}

