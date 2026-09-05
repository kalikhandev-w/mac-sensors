import MacSensorsCore

func runSMCDecodeTests() {
    // Test vectors computed with Python struct.pack (see plan).
    checkEqual(SMCDecode.fourCC("Tp01"), 0x5470_3031, "fourCC Tp01")
    checkEqual(SMCDecode.fourCC("flt "), 0x666c_7420, "fourCC 'flt '")
    checkEqual(SMCDecode.fourCC("abc"), nil, "fourCC rejects 3 chars")
    checkEqual(SMCDecode.typeString(0x666c_7420), "flt ", "typeString")

    checkClose(SMCDecode.flt([154, 153, 109, 66]), 59.4, tolerance: 0.001, "flt 59.4")
    checkClose(SMCDecode.flt([0, 96, 17, 69]), 2326.0, tolerance: 0.001, "flt 2326")
    checkClose(SMCDecode.flt([0, 0, 192, 191]), -1.5, tolerance: 0.001, "flt -1.5")
    checkEqual(SMCDecode.flt([1, 2, 3]), nil, "flt rejects short input")

    checkClose(SMCDecode.sp78([59, 128]), 59.5, tolerance: 0.001, "sp78 59.5")
    checkClose(SMCDecode.sp78([254, 128]), -1.5, tolerance: 0.001, "sp78 -1.5 (negative)")
    checkEqual(SMCDecode.sp78([1]), nil, "sp78 rejects short input")

    checkClose(SMCDecode.fpe2([39, 16]), 2500.0, tolerance: 0.001, "fpe2 2500")
    checkClose(SMCDecode.fpe2([0, 1]), 0.25, tolerance: 0.001, "fpe2 0.25")

    checkClose(SMCDecode.value(type: "flt ", bytes: [0, 96, 17, 69]), 2326.0, tolerance: 0.001, "value flt")
    checkClose(SMCDecode.value(type: "sp78", bytes: [59, 128]), 59.5, tolerance: 0.001, "value sp78")
    checkClose(SMCDecode.value(type: "fpe2", bytes: [39, 16]), 2500.0, tolerance: 0.001, "value fpe2")
    checkEqual(SMCDecode.value(type: "ui8 ", bytes: [2]), nil, "value unknown type")
}
