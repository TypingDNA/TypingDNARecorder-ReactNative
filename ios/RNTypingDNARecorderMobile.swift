//
//  RNTypingDNARecorderMobile.swift iOS version
//  tdnaIOS
//
//  TypingDNA - Typing Biometrics Recorder Mobile iOS
//  https://www.typingdna.com
//
//
//  @version 3.1
//  @author Raul Popa & Stefan Endres
//  @copyright TypingDNA Inc. https://www.typingdna.com
//  @license http://www.apache.org/licenses/LICENSE-2.0
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation;
import UIKit;
import CoreMotion;
import os.log;
import _SwiftOSOverlayShims;

/**
 * Instantiate RNTypingDNARecorderMobile class in your project and make sure you also add UIViewExtention to your project
 */

// DO NOT MODIFY
@objc(RNTypingDNARecorderMobile)
open class RNTypingDNARecorderMobile: NSObject {
    
    // Main initialization params
    
    static var mobile = true;
    static var maxHistoryLength = 500;
    static var replaceMissingKeys = true;
    static var replaceMissingKeysPerc = 7;
    static var recording = true;
    static var mouseRecording = true;
    static var mouseMoveRecording = true;
    static var spKeyRecording = true;
    static var diagramRecording = true;
    static var motionFixedData = true;
    static var motionArrayData = true;
    static let version = 3.1;
    fileprivate static var flags = "3"; // SWIFT (4.2) for IOS
    fileprivate static var maxSeekTime = 1500;
    fileprivate static var maxPressTime = 300;
    fileprivate static var spKeyCodes = [51, 36, 49];
    fileprivate static var spKeyCodesObj = [51: true, 36: true, 49: true];
    fileprivate static let keyCodes = [65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 32, 39, 44, 46, 59, 63, 45, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57]
    fileprivate static let maxKeyCode = 250;
    fileprivate static let defaultHistoryLength = 160;
    fileprivate static var keyCodesObj = [Int:Bool]();
    fileprivate static var wfk = [Int:Bool]();
    fileprivate static var sti = [Int:Int]();
    fileprivate static var skt = [Int:Int]();
    fileprivate static var dwfk = [Int:Bool]();
    fileprivate static var dsti = [Int:Int]();
    fileprivate static var dskt = [Int:Int]();
    fileprivate static var drkc = [Int:Int]();
    fileprivate static var pt1:Int = 0;
    fileprivate static var ut1:Int = 0;
    fileprivate static var prevKeyCode = 0;
    fileprivate static var lastPressedKey = 0;
    fileprivate static var historyStack = [[Any]]();
    fileprivate static var stackDiagram = [[Any]]();
    fileprivate static var savedMissingAvgValuesHistoryLength = -1;
    fileprivate static var savedMissingAvgValuesSeekTime:Int = 0;
    fileprivate static var savedMissingAvgValuesPressTime:Int = 0;
    fileprivate static var pointerInputMouse = false;
    fileprivate static var pointerInputTrackpad = false;
    fileprivate static var keyboardTypeInternal = false;
    fileprivate static var keyboardTypeExternal = false;
    static var targetIds = [String]();
    fileprivate static var lastTarget = "";
    fileprivate static var lastTargetFound = false;
    fileprivate static var screenWidth = UIScreen.main.bounds.width * UIScreen.main.nativeScale;
    fileprivate static var screenHeight = UIScreen.main.bounds.height * UIScreen.main.nativeScale;
    fileprivate static var initialized = false;
    static var kpTimer:Timer = Timer();
    fileprivate static var logLevel = 0;
    fileprivate static var debugMode = false;
    
    public override init() {
        RNTypingDNARecorderMobile.log(message: "[TypingDNA] Creating the recorder...", level: 1);
        if (!RNTypingDNARecorderMobile.initialized) {
            RNTypingDNARecorderMobile.log(message: "[TypingDNA] The recorder was not initialized...", level: 1);
            RNTypingDNARecorderMobile.initialized = RNTypingDNARecorderMobile._initialize();
        }
    }
    
    @objc
    static public func debuggingMode(_debugMode: Bool, _logLevel: Int) {
        debugMode = _debugMode;
        logLevel = _logLevel;
    }
    
    static fileprivate func log(message: StaticString, level: Int, dso: UnsafeRawPointer = #dsohandle, _ args: CVarArg...) {
        
        if (debugMode && level <= logLevel) {
            let ra = _swift_os_log_return_address()
            message.withUTF8Buffer { (buf: UnsafeBufferPointer<UInt8>) in
                buf.baseAddress!.withMemoryRebound(to: CChar.self, capacity: buf.count) { str in
                    withVaList(args) { valist in
                        _swift_os_log(dso, ra, .default, .default, str, valist)
                    }
                }
            }
        }
    }
    
    @objc
    static public func _initialize() -> Bool {
        log(message: "[TypingDNA] Initializing the recorder...", level: 1);
        for i in 0..<keyCodes.count {
            keyCodesObj[keyCodes[i]] = true;
        }
        for i in 0..<spKeyCodes.count {
            keyCodesObj[spKeyCodes[i]] = true;
        }
        reset();
        start();
        return true;
    }
    
    /**
     * EXAMPLE:
     * typingPattern:String = RNTypingDNARecorderMobile.getTypingPattern(type, length, text, textId, target, caseSensitive);
     *
     * PARAMS:
     * type:Int = 0; // 1,2 for diagram pattern (short identical texts - 2 for extended diagram), 0 for any-text typing pattern (random text)
     * length:Int = 0; // (Optional) the length of the text in the history for which you want the typing pattern, 0 = ignore
     * text:String = ""; // (Only for type 1/2) a typed string that you want the typing pattern for
     * textId:Int = 0; // (Optional, only for type 1/2) a personalized id for the typed text, 0 = ignore
     * target:UITextField = nil; // (Optional, only for type 1/2) Get a typing pattern only for text typed in a certain text field.
     * caseSensitive:Bool = false; // (Optional, only for type 1/2) Used only if you pass a text for type 1/2
     */
    @objc
    static public func getTypingPattern(type:Int, length:Int, text:String, textId:Int, target:UITextField?, caseSensitive:Bool) -> String {
        log(message: "[TypingDNA] Get typing pattern called with { type: %d, length: %d, text: %@, textId: %d, target: %@, caseSensitive: %d }", level: 2, type, length, text, textId, String(target?.hashValue ?? -1), caseSensitive);
        if (type == 1) {
            return getDiagram(false, text, textId, length, target, caseSensitive);
        } else if (type == 2) {
            return getDiagram(true, text, textId, length, target, caseSensitive);
        } else {
            return get(length).replacingOccurrences(of: ".0,", with: ",");
        }
    }
    
    @objc
    static public func getTypingPattern(_ type:Int, _ length:Int, _ text:String, _ textId:Int, _ target:UITextField?, _ caseSensitive:Bool) -> String {
        log(message: "[TypingDNA] Get typing pattern called with { type: %d, length: %d, text: %@, textId: %d, target: %@, caseSensitive: %d }", level: 2, length, text, textId, String(target?.hashValue ?? -1), caseSensitive);
        return getTypingPattern(type:type, length:length, text:text, textId:textId, target:target, caseSensitive:caseSensitive);
    }
    
    @objc
    static public func getTypingPattern(_ type:Int, _ length:Int, _ text:String, _ textId:Int, _ target:UITextField?) -> String {
        log(message: "[TypingDNA] Get typing pattern called with { type: %d, length: %d, text: %@, textId: %d, target: %@, caseSensitive: %d }", level: 2, length, text, textId, String(target?.hashValue ?? -1), "false");
        return getTypingPattern(type:type, length:length, text:text, textId:textId, target:target, caseSensitive:false);
    }
    
    @objc
    static public func getTypingPattern(_ type:Int, _ length:Int, _ text:String, _ textId:Int) -> String {
        log(message: "[TypingDNA] Get typing pattern called with { type: %d, length: %d, text: %@, textId: %d, target: %@, caseSensitive: %d }", level: 2, type, length, text, textId, "N/A", "false");
        return getTypingPattern(type:type, length:length, text:text, textId:textId, target:nil, caseSensitive:false);
    }
    
    /**
     * Resets the history stack of recorded typing events (and mouse if all:true).
     */
    @objc
    static public func reset(_ all: Bool) {
        log(message: "[TypingDNA] Resetting the recorder...", level: 1);
        historyStack = [[Int]]();
        stackDiagram = [[Int]]();
        pt1 = getTime();
        ut1 = getTime();
    }
    @objc
    static public func reset() {
        reset(false);
    }
    
    /**
     * Automatically called at initialization. It starts the recording of typing
     * events. You only have to call .start() to resume recording after a .stop()
     */
    @objc
    static public func start() {
        log(message: "[TypingDNA] Starting the recorder v3.1...", level: 1);
        recording = true;
        diagramRecording = true;
    }
    
    /**
     * Ends the recording of further typing events.
     */
    @objc
    static public func stop() {
        log(message: "[TypingDNA] Stopping the recorder...", level: 1);
        recording = false;
        diagramRecording = false;
    }
    
    /**
     * Adds a target to the targetIds array.
     */
    @objc
    static public func addTarget(_ targetField:UITextField) {
        let target = String(targetField.hashValue);
        log(message: "[TypingDNA] Adding a target { target: %@, previous: %@ }", level: 1, targetIds.debugDescription);
        let targetLength = targetIds.count;
        var targetFound = false;
        if (targetLength > 0) {
            for i in 0..<targetLength {
                if (targetIds[i] == target) {
                    targetFound = true;
                    break;
                }
            }
            if (!targetFound) {
                targetIds.append(target);
                KIOSlastText.updateValue(targetField.text ?? "", forKey: String(targetField.hash));
                targetField.addTarget(self, action: #selector(UIW_KIOSkeyReleased(_:)), for: .editingChanged);
            }
        } else {
            targetIds.append(target);
            KIOSlastText.updateValue(targetField.text ?? "", forKey: String(targetField.hash));
            targetField.addTarget(self, action: #selector(UIW_KIOSkeyReleased(_:)), for: .editingChanged);
        }
    }
    
    /**
     * Adds a target to the targetIds array.
     */
    @objc
    static public func removeTarget(_ targetField:UITextField) {
        let target = String(targetField.hashValue);
        log(message: "[TypingDNA] Removing a target { target: %@ }", level: 1, target);
        let targetLength = targetIds.count;
        if (targetLength > 0) {
            for i in 0..<targetLength {
                if (targetIds[i] == target) {
                    targetIds.remove(at: i);
                    KIOSlastText.removeValue(forKey: String(targetField.hash));
                    targetField.removeTarget(nil, action: nil, for: .editingChanged);
                    break;
                }
            }
        }
    }
    
    @objc
    static public func keyReleased(_ keyCode: Int, _ keyChar: Int, _ modifiers: Bool, _ upTime:Int, _ target:String, _ kpGet:[Any], _ xy:String) {
        if ((!recording && !diagramRecording) || keyCode >= maxKeyCode) {
            log(message: "[TypingDNA] Recording is stopped or invalid key code { keyCode: %d }", level: 2, keyCode);
            return;
        }
        if (!isTarget(target)) {
            log(message: "[TypingDNA] Received key is for an invalid target { target: %@ }", level: 2, target);
            return;
        }
        log(message: "[TypingDNA] Key released { keyCode: %d, keyChar: %d, modifiers: %d, upTime: %d, target: %@, kpGet: %@, xy: %@", level: 2, keyCode, keyChar, modifiers, upTime, target, kpGet.debugDescription, xy);
        let t0 = ut1;
        ut1 = upTime;
        let seekTime = ut1 - t0;
        let downTime = kpGet[0] as! Int;
        let pressTime = (downTime != 0) ? ut1 - downTime : 0;
        if(recording == true && !modifiers) {
            if(keyCodesObj[keyCode] == true) {
                let arr:[Any] = [keyCode, seekTime, pressTime, prevKeyCode, ut1, target];
                historyAdd(arr);
                prevKeyCode = keyCode;
            }
        }
        if (diagramRecording == true) {
            let kp0 = kpGet[1] as! String;
            let kp1 = kpGet[2] as! String;
            let kp2 = kpGet[3] as! String;
            let kp3 = kpGet[4] as! String;
            let arrD:[Any] = [keyCode, seekTime, pressTime, keyChar, ut1, target, kp0, kp1, kp2, kp3, xy];
            historyAddDiagram(arrD);
        }
    }
    
    @objc
    static public func fnv1a(_ str: String) -> String {
        log(message: "[TypingDNA] Hashing { str: %@ }", level: 3, str);
        return String(fnv1a_32(bytes: str.utf8));
    }
    
    // Private functions
    
    fileprivate static func getSpecialKeys() -> String {
        log(message: "[TypingDNA] Getting special keys...", level: 3);
        var returnArr = [Int]();
        let length = historyStack.count;
        var historyStackObj = [Int:[Int]]();
        let spKeyCodesLen = spKeyCodes.count;
        for i in 0..<spKeyCodesLen {
            historyStackObj[spKeyCodes[i]] = [Int]();
        }
        if (length > 0) {
            for i in 1...length {
                let arr:[Any] = historyStack[length - i];
                if (spKeyCodesObj[arr[0] as! Int] != nil) {
                    if (spKeyCodesObj[arr[0] as! Int] == true) {
                        let keyCode = arr[0] as! Int;
                        let pressTime = arr[2] as! Int;
                        if (pressTime <= maxPressTime) {
                            historyStackObj[keyCode]!.append(pressTime);
                        }
                    }
                }
            }
            var arrI = [Int]();
            var arrLen = 0;
            for i in 0..<spKeyCodesLen {
                arrI = fo(historyStackObj[spKeyCodes[i]]!);
                arrLen = arrI.count;
                returnArr.append(arrLen);
                if (arrLen > 1) {
                    returnArr.append(Int(round(avg(arrI))));
                    returnArr.append(Int(round(sd(arrI))));
                } else if (arrLen == 1) {
                    returnArr.append(arrI[0]);
                    returnArr.append(-1);
                } else {
                    returnArr.append(-1);
                    returnArr.append(-1);
                }
            }
            returnArr.append(0);
            returnArr.append(-1);
            returnArr.append(-1);
            returnArr.append(0);
            returnArr.append(-1);
            returnArr.append(-1);
            let returnStrArr:[String] = returnArr.map({String(describing: $0)});
            log(message: "[TypingDNA] Special keys { keys: %@ }", level: 3, returnStrArr.debugDescription);
            return returnStrArr.joined(separator: ",");
        } else {
            log(message: "[TypingDNA] Default special keys { keys: %@ }", level: 3, "0,-1,-1,0,-1,-1,0,-1,-1,0,-1,-1,0,-1,-1");
            return "0,-1,-1,0,-1,-1,0,-1,-1,0,-1,-1,0,-1,-1";
        }
    }
    
    fileprivate static func historyAdd(_ arr: [Any]) {
        log(message: "[TypingDNA] Adding to history stack { arr: %@ }", level: 2, arr.debugDescription);
        historyStack.append(arr);
        if (historyStack.count > maxHistoryLength) {
            historyStack.remove(at: 0);
        }
    }
    
    fileprivate static func historyAddDiagram(_ arr: [Any]) {
        log(message: "[TypingDNA] Adding to stack diagram { arr: %@ }", level: 2, arr.debugDescription);
        stackDiagram.append(arr);
    }
    
    fileprivate static func getSeek(_ length: Int) -> [Int] {
        log(message: "[TypingDNA] Get seek { length: %d }", level: 3, length);
        var length = length;
        let historyTotalLength = historyStack.count;
        if (length > historyTotalLength) {
            length = historyTotalLength;
        }
        var seekArr = [Int]();
        if (length > 0) {
            for i in 1...length {
                let seekTime = historyStack[historyTotalLength - i][1] as! Int;
                if (seekTime < maxSeekTime && seekTime > 0) {
                    seekArr.append(seekTime);
                }
            }
        }
        log(message: "[TypingDNA] Seek array is { seekArr: %@ }", level: 3, seekArr.debugDescription);
        return seekArr;
    }
    
    fileprivate static func getPress(_ length: Int) -> [Int] {
        log(message: "[TypingDNA] Getting press { length: %d }", level: 2, length);
        var length = length;
        let historyTotalLength = historyStack.count;
        if (length > historyTotalLength) {
            length = historyTotalLength;
        }
        var pressArr = [Int]();
        if (length > 0) {
            for i in 1...length {
                let pressTime = historyStack[historyTotalLength - i][2] as! Int;
                if (pressTime < maxPressTime && pressTime > 0) {
                    pressArr.append(pressTime);
                }
            }
        }
        log(message: "[TypingDNA] Press array is { pressArr: %@ }", level: 2, pressArr.debugDescription);
        return pressArr;
    }
    
    fileprivate static func fnv1a_32<S: Sequence>(bytes: S) -> UInt32 where S.Iterator.Element == UInt8 {
        var hash:UInt32 = 0x721b5ad4;
        let prime:UInt32 = 16777619;
        for byte in bytes {
            hash ^= UInt32(byte);
            hash = hash &* prime;
        }
        return hash;
    }
    
    fileprivate static func getDiagram(_ extended: Bool,_ str: String,_ textId: Int,_ tpLength: Int,_ target:UITextField?,_ caseSensitive: Bool) -> String {
        log(message: "[TypingDNA] Getting the diagram { extended: %d, str: %@, textId: %d, tpLength: %d, target: %@, caseSensitive: %d }", level: 2, extended, str, textId, tpLength, String(target?.hashValue ?? -1), caseSensitive);
        var returnStr:String = "";
        var motionArr:[String] = [];
        var kpzaArr:[String] = [];
        var kpxrArr:[String] = [];
        var kpyrArr:[String] = [];
        let diagramType = (extended == true) ? 1 : 0;
        var stackDiagram = self.stackDiagram;
        var targetId = "";
        var str:String = str;
        if (target != nil) {
            if (targetIds.count > 0) {
                targetId = String(target!.hashValue);
                stackDiagram = sliceStackByTargetId(stackDiagram, targetId);
            }
            if (str == "") {
                str = target!.text!;
                log(message: "[TypingDNA] New str value { str: %@ }", level: 2, str);
            }
        }
        var missingCount = 0;
        let diagramHistoryLength = stackDiagram.count;
        var strLength = tpLength;
        if (str.count > 0) {
            strLength = str.count;
        } else if (strLength > diagramHistoryLength || strLength == 0) {
            strLength = diagramHistoryLength;
        }
        var returnTextId:String = "0";
        if (textId == 0 && str.count > 0) {
            returnTextId = fnv1a(str);
        } else {
            returnTextId = "" + String(textId);
        }
        let mobile:String = (self.mobile == true) ? "1" : "0";
        let specialKeys = getSpecialKeys();
        let deviceSignature = getDeviceSignature();
        let returnStr0:String = [mobile, version, flags, diagramType, strLength, returnTextId, specialKeys, deviceSignature].map({String(describing: $0)}).joined(separator: ",");
        returnStr += returnStr0;
        if (str.count > 0) {
            let strLower:String = str.lowercased();
            let strUpper:String = str.uppercased();
            var lastFoundPos:[Int] = [Int]();
            var lastPos:Int = 0;
            var strUpperCharCode:Int;
            var currentSensitiveCharCode:Int;
            for i in 0..<str.count {
                let index = str.index(str.startIndex, offsetBy: i);
                if (UnicodeScalar(String(strUpper[index])) == nil) {
                    log(message: "[TypingDNA] Unicode error", level: 2);
                    return "unicode error";
                }
                let currentCharCode = Int(UnicodeScalar(String(str[index]))!.value);
                if (!caseSensitive) {
                    strUpperCharCode = Int(UnicodeScalar(String(strUpper[index]))!.value);
                    currentSensitiveCharCode = (strUpperCharCode != currentCharCode) ? strUpperCharCode : Int(UnicodeScalar(String(strLower[index]))!.value);
                } else {
                    currentSensitiveCharCode = currentCharCode;
                }
                var startPos = lastPos;
                var finishPos = diagramHistoryLength;
                var found = false;
                while (found == false) {
                    for j in startPos..<finishPos {
                        let arr:[Any] = stackDiagram[j];
                        let charCode = arr[3] as! Int;
                        if (charCode == currentCharCode || (!caseSensitive && charCode == currentSensitiveCharCode)) {
                            found = true;
                            if (j == lastPos) {
                                lastPos += 1;
                                lastFoundPos = [Int]();
                            } else {
                                lastFoundPos.append(j);
                                let len = lastFoundPos.count;
                                if (len > 1 && lastFoundPos[len - 1] == lastFoundPos[len - 2 ] + 1) {
                                    lastPos = j + 1;
                                    lastFoundPos = [Int]();
                                }
                            }
                            let keyCode = arr[0] as! Int;
                            let seekTime = arr[1] as! Int;
                            let pressTime = arr[2] as! Int;
                            if (extended == true) {
                                returnStr += "|" + [charCode, seekTime, pressTime, keyCode].map({String(describing:$0)}).joined(separator: ",");
                            } else {
                                returnStr += "|" + [seekTime, pressTime].map({String(describing:$0)}).joined(separator: ",");
                            }
                            if (motionFixedData == true) {
                                var el = (arr[6] as! String);
                                if (extended == true) {
                                    el += "," + (arr[10] as! String);
                                }
                                motionArr.append(el);
                            }
                            if (motionArrayData == true) {
                                kpzaArr.append(arr[7] as! String);
                                kpxrArr.append(arr[8] as! String);
                                kpyrArr.append(arr[9] as! String);
                            }
                            break;
                        }
                    }
                    if (found == false) {
                        if (startPos != 0) {
                            startPos = 0;
                            finishPos = lastPos;
                        } else {
                            found = true;
                            if (replaceMissingKeys == true) {
                                missingCount += 1;
                                var seekTime, pressTime: Int;
                                if (savedMissingAvgValuesHistoryLength == -1 || savedMissingAvgValuesHistoryLength != diagramHistoryLength) {
                                    let histSktF = fo(getSeek(200));
                                    let histPrtF = fo(getPress(200));
                                    if (histSktF.count > 0 && histPrtF.count > 0) {
                                        seekTime = Int(round(avg(histSktF)));
                                        pressTime = Int(round(avg(histPrtF)));
                                        savedMissingAvgValuesSeekTime = seekTime;
                                        savedMissingAvgValuesPressTime = pressTime;
                                        savedMissingAvgValuesHistoryLength = diagramHistoryLength;
                                    } else {
                                        seekTime = savedMissingAvgValuesSeekTime;
                                        pressTime = savedMissingAvgValuesPressTime;
                                    }
                                } else {
                                    seekTime = savedMissingAvgValuesSeekTime;
                                    pressTime = savedMissingAvgValuesPressTime;
                                }
                                let missing = 1;
                                if (extended == true) {
                                    returnStr += "|" + [currentCharCode, seekTime, pressTime, currentCharCode, missing].map({String(describing:$0)}).joined(separator: ",");
                                } else {
                                    returnStr += "|" + [seekTime, pressTime].map({String(describing:$0)}).joined(separator: ",");
                                }
                                if (motionFixedData == true) {
                                    motionArr.append("");
                                }
                                if (motionArrayData == true) {
                                    kpzaArr.append("");
                                    kpxrArr.append("");
                                    kpyrArr.append("");
                                }
                                break;
                            }
                        }
                    }
                }
                if (replaceMissingKeysPerc < missingCount * 100 / strLength) {
                    returnStr = returnStr0;
                    log(message: "[TypingDNA] Diagram is empty (too many missing keys) { missingCount: %d, strLength: %d }", level: 2, missingCount, strLength);
                    return "";
                }
            }
        } else {
            var startCount = 0;
            if (tpLength > 0) {
                startCount = diagramHistoryLength - tpLength;
            }
            if (startCount < 0) {
                startCount = 0;
            }
            for i in startCount..<diagramHistoryLength {
                let arr:[Any] = stackDiagram[i];
                let keyCode = arr[0] as! Int;
                let seekTime = arr[1] as! Int;
                let pressTime = arr[2] as! Int;
                if (extended == true) {
                    let charCode = arr[3] as! Int;
                    returnStr += "|" + [charCode, seekTime, pressTime, keyCode].map({String(describing:$0)}).joined(separator: ",");
                } else {
                    returnStr += "|" + [seekTime, pressTime].map({String(describing:$0)}).joined(separator: ",");
                }
                if (motionFixedData == true) {
                    var el = (arr[6] as! String);
                    if (extended == true) {
                        el += "," + (arr[10] as! String);
                    }
                    motionArr.append(el);
                }
                if (motionArrayData == true) {
                    kpzaArr.append(arr[7] as! String);
                    kpxrArr.append(arr[8] as! String);
                    kpyrArr.append(arr[9] as! String);
                }
            }
        }
        if (motionFixedData == true) {
            returnStr += "#" + motionArr.map({String(describing:$0)}).joined(separator: "|");
        }
        if (motionArrayData == true) {
            returnStr += "#" + kpzaArr.map({String(describing:$0)}).joined(separator: "|");
            returnStr += "/" + kpxrArr.map({String(describing:$0)}).joined(separator: "|");
            returnStr += "/" + kpyrArr.map({String(describing:$0)}).joined(separator: "|");
        }
        log(message: "[TypingDNA] Diagram is { returnStr: %@ } ", level: 2, returnStr);
        return returnStr;
    }
    
    fileprivate static func get(_ length: Int) -> String {
        log(message: "[TypingDNA] Getting typing pattern { length: %d }", level: 3, length);
        let historyTotalLength = historyStack.count;
        var length = length;
        if (length == 0) {
            length = defaultHistoryLength;
        }
        if (length > historyTotalLength) {
            length = historyTotalLength;
        }
        var historyStackObjSeek:[Int:[Int]] = [Int:[Int]]();
        var historyStackObjPress:[Int:[Int]] = [Int:[Int]]();
        var historyStackObjPrev:[Int:[Int]] = [Int:[Int]]();
        if (length > 0) {
            for i in 1...length {
                let arr:[Any] = historyStack[historyTotalLength - i];
                let keyCode = arr[0] as! Int;
                let seekTime = arr[1] as! Int;
                let pressTime = arr[2] as! Int;
                let prevKeyCode = arr[3] as! Int;
                if (keyCodesObj[keyCode] == true) {
                    if (seekTime <= maxSeekTime) {
                        var sarr:[Int] = [Int]();
                        if (historyStackObjSeek[keyCode] == nil) {
                            sarr = [Int]();
                        } else {
                            sarr = historyStackObjSeek[keyCode]!;
                        }
                        sarr.append(seekTime);
                        historyStackObjSeek[keyCode] = sarr;
                        if (prevKeyCode != 0) {
                            if (keyCodesObj[prevKeyCode] == true) {
                                var poarr:[Int] = [Int]();
                                if (historyStackObjPrev[keyCode] == nil) {
                                    poarr = [Int]();
                                } else {
                                    poarr = historyStackObjPrev[keyCode]!;
                                }
                                poarr.append(seekTime);
                                historyStackObjPrev[prevKeyCode] = poarr;
                            }
                        }
                    }
                    if (pressTime <= maxPressTime) {
                        var prarr:[Int] = [Int]();
                        if (historyStackObjPress[keyCode] == nil) {
                            prarr = [Int]();
                        } else {
                            prarr = historyStackObjPress[keyCode]!;
                        }
                        prarr.append(pressTime);
                        historyStackObjPress[keyCode] = prarr;
                    }
                }
            }
            var meansArr:[Int:[Double]] = [Int:[Double]]();
            let zl:Double = 0.0000001;
            let histRev = length;
            let histSktF:[Int] = fo(getSeek(length));
            let histPrtF:[Int] = fo(getPress(length));
            var pressHistMean:Double = round(avg(histPrtF));
            if (pressHistMean.isNaN || pressHistMean.isInfinite) {
                pressHistMean = 0.0;
            }
            var seekHistMean:Double = round(avg(histSktF));
            if (seekHistMean.isNaN || seekHistMean.isInfinite) {
                seekHistMean = 0.0;
            }
            var pressHistSD:Double = round(sd(histPrtF));
            if (pressHistSD.isNaN || pressHistSD.isInfinite) {
                pressHistSD = 0.0;
            }
            var seekHistSD:Double = round(sd(histSktF));
            if (seekHistSD.isNaN || seekHistSD.isInfinite) {
                seekHistSD = 0.0;
            }
            let charMeanTime:Double = seekHistMean + pressHistMean;
            let pressRatio:Double = rd((pressHistMean + zl) / (charMeanTime + zl));
            let seekToPressRatio:Double = rd((1 - pressRatio) / pressRatio);
            let pressSDToPressRatio:Double = rd((pressHistSD + zl) / (pressHistMean + zl));
            let seekSDToPressRatio:Double = rd((seekHistSD + zl) / (pressHistMean + zl));
            var cpm = round(6E4 / (charMeanTime + zl));
            if (charMeanTime == 0) {
                cpm = 0;
            }
            for i in 0..<keyCodes.count {
                let keyCode = keyCodes[i];
                var srev = 0;
                var prrev = 0;
                var porev = 0;
                var sarr:[Int] = [Int]();
                if (historyStackObjSeek[keyCode] != nil) {
                    sarr = historyStackObjSeek[keyCode]!;
                    srev = sarr.count;
                }
                var prarr:[Int] = [Int]();
                if (historyStackObjPress[keyCode] != nil) {
                    prarr = historyStackObjPress[keyCode]!;
                    prrev = prarr.count;
                }
                var poarr:[Int] = [Int]();
                if (historyStackObjPrev[keyCode] != nil) {
                    poarr = historyStackObjPrev[keyCode]!;
                    porev = poarr.count;
                }
                let rev = prrev;
                var seekMean:Double = 0.0;
                var pressMean:Double = 0.0;
                var postMean:Double = 0.0;
                var seekSD:Double = 0.0;
                var pressSD:Double = 0.0;
                var postSD:Double = 0.0;
                switch (srev) {
                case 0:
                    break;
                case 1:
                    seekMean = rd((Double(sarr[0]) + zl) / (seekHistMean + zl));
                    break;
                default:
                    let arr:[Int] = fo(sarr);
                    seekMean = rd((avg(arr) + zl) / (seekHistMean + zl));
                    seekSD = rd((sd(arr) + zl) / (seekHistSD + zl));
                }
                switch (prrev) {
                case 0:
                    break;
                case 1:
                    pressMean = rd((Double(prarr[0]) + zl) / (pressHistMean + zl));
                    break;
                default:
                    let arr:[Int] = fo(prarr);
                    pressMean = rd((avg(arr) + zl) / (pressHistMean + zl));
                    pressSD = rd((sd(arr) + zl) / (pressHistSD + zl));
                }
                switch (porev) {
                case 0:
                    break;
                case 1:
                    postMean = rd((Double(poarr[0]) + zl) / (seekHistMean + zl));
                    break;
                default:
                    let arr:[Int] = fo(poarr);
                    postMean = rd((avg(arr) + zl) / (seekHistMean + zl));
                    postSD = rd((sd(arr) + zl) / (seekHistSD + zl));
                }
                var varr:[Double] = [Double]();
                varr.append(Double(rev));
                varr.append(seekMean);
                varr.append(pressMean);
                varr.append(postMean);
                varr.append(seekSD);
                varr.append(pressSD);
                varr.append(postSD);
                meansArr[keyCode] = varr;
            }
            
            var arr:[String] = [String]();
            arr.append(String(histRev));
            arr.append(String(cpm));
            arr.append(String(charMeanTime));
            arr.append(String(pressRatio));
            arr.append(String(seekToPressRatio));
            arr.append(String(pressSDToPressRatio));
            arr.append(String(seekSDToPressRatio));
            arr.append(String(pressHistMean));
            arr.append(String(seekHistMean));
            arr.append(String(pressHistSD));
            arr.append(String(seekHistSD));
            for c in 0...6 {
                for i in 0..<keyCodes.count {
                    let keyCode = keyCodes[i];
                    var varr:[Double] = [Double]();
                    varr = meansArr[keyCode]!;
                    var val:Double = varr[c];
                    if (Double(val).isNaN) {
                        val = 0.0;
                    } else if (val == 0 && c > 0) {
                        val = 1.0;
                        arr.append(String(val));
                    } else if (c == 0) {
                        arr.append(String(val));
                    } else {
                        arr.append(String(val))
                    }
                }
            }
            let mobile:String = (self.mobile == true) ? "1" : "0";
            arr.append(mobile);
            arr.append(String(version));
            arr.append(String(flags));
            arr.append("-1"); // diagramType
            arr.append(String(describing: length)); // strLength/histRev
            arr.append("0"); // textId
            arr.append(getSpecialKeys());
            arr.append(getDeviceSignature());
            let typingPattern:String = arr.joined(separator: ",");
            log(message: "[TypingDNA] Typing pattern is { typingPattern: %@ } ", level:
                3, typingPattern);
            return typingPattern;
        } else {
            log(message: "[TypingDNA] Typing pattern is empty", level: 3);
            return "";
        }
    }
    
    @objc
    static public func getDeviceSignature() -> String {
        log(message: "[TypingDNA] Getting device signature...", level: 3);
        let deviceType = 2; // {0:unknown, 1:pc, 2:phone, 3:tablet}
        let deviceModel = padRight(s: fnv1a("Apple"), n: 12) + fnv1a(UIDevice.current.modelName); // fnv1aHash of device manufacturer + "-" + model
        let deviceId: String;
        if let uuid = UIDevice.current.identifierForVendor?.uuidString {
            deviceId = fnv1a(uuid);
        }
        else {
            deviceId = "0";
        }
        let isMobile = 2; // {0:unknown, 1:pc, 2:mobile}
        let operatingSystem = 5; // {0:unknown/other, 1:Windows, 2:MacOS, 3:Linux, 4:ChromeOS, 5:iOS, 6: Android}
        let programmingLanguage = 3; // {0:unknown, 1:JavaScript, 2:Java, 3:Swift, 4:C++, 5:C#, 6:AndroidJava}
        let language = Locale.current.languageCode!;
        let systemLanguage:String = fnv1a(language); // fnv1aHash of language
        let isTouchDevice = 2; // {0:unknown, 1:no, 2:yes}
        let pressType = 1; // {0:unknown, 1:recorded, 2:calculated, 3:mixed}
        let keyboardInput = 0; // {0:unknown, 1:keyboard, 2:touchscreen, 3:mixed}
        let keyboardType = 0; // {0:unknown, 1:internal, 2:external, 3:mixed}
        let pointerInput = 0; // {0:unknown, 1:mouse, 2:touchscreen, 3:trackpad, 4:other, 5:mixed}
        let browserType = 0; // {0:unknown, 1:Chrome, 2:Firefox, 3:Opera, 4:IE, 5: Safari, 6: Edge, 7:AndroidWK}
        let displayWidth = screenWidth; // screen width in pixels
        let displayHeight = screenHeight; // screen height in pixels
        let orientation: Int;
        switch UIApplication.shared.statusBarOrientation {
        case UIInterfaceOrientation.portrait, UIInterfaceOrientation.portraitUpsideDown:
            orientation = 1;
        case UIInterfaceOrientation.landscapeLeft, UIInterfaceOrientation.landscapeRight:
            orientation = 2;
        default:
            orientation = 1;
        }
        let osVersion = Int(String(ProcessInfo.processInfo.operatingSystemVersion.majorVersion) + String(ProcessInfo.processInfo.operatingSystemVersion.minorVersion))!; // numbers only
        let browserVersion = 0; // numbers only
        let cookieId = 0; // only in iframe
        
        let signatureArr:[String] = [deviceType,deviceModel,deviceId,isMobile,operatingSystem,programmingLanguage,systemLanguage,isTouchDevice,pressType,keyboardInput,keyboardType,pointerInput,browserType,displayWidth,displayHeight,orientation,osVersion,browserVersion,cookieId].map({String(describing: $0)});
        let signatureStr = signatureArr.joined(separator: "-");
        let signature:String = fnv1a(signatureStr); // fnv1aHash of all above!
        
        let returnArr:[String] = [deviceType,deviceModel,deviceId,isMobile,operatingSystem,programmingLanguage,systemLanguage,isTouchDevice,pressType,keyboardInput,keyboardType,pointerInput,browserType,displayWidth,displayHeight,orientation,osVersion,browserVersion,cookieId,signature].map({String(describing: $0)});
        let returnStr = returnArr.joined(separator: ",");
        log(message: "[TypingDNA] Device signature is { returnStr: %@ }", level: 3, returnStr);
        return returnStr;
    }
    
    @objc
    static fileprivate func padRight(s: String, n: Int) -> String {
        let lengthDiff = n - s.count;
        if (lengthDiff <= 0) {
            return s;
        }
        return s + String(repeating: "0", count: (n - s.count));
    }
    
    @objc
    static public func getTime() -> Int{
        return Int(CACurrentMediaTime()*1000);
    }
    
    // Filter outliers
    @objc
    fileprivate static func fo(_ arr: [Double]) -> [Double] {
        log(message: "[TypingDNA] Filtering outliers { arr: %@ }", level: 3, arr.debugDescription);
        if (arr.count < 1) {
            log(message: "[TypingDNA] Outliers filtered { arr: %@ }", level: 3, arr.debugDescription);
            return arr;
        }
        var values = arr.sorted {$0 < $1};
        let asd = sd(values);
        let index = Int(values.count/2);
        let aMean = values[index];
        let multiplier:Double = 2;
        let maxVal = aMean + multiplier * asd;
        var minVal = aMean - multiplier * asd;
        if (arr.count < 20) {
            minVal = 0;
        }
        let fVal = values.filter {$0 < maxVal && $0 > minVal};
        log(message: "[TypingDNA] Outliers filtered { fVal: %@ }", level: 3, fVal.debugDescription);
        return fVal;
    }
    
    fileprivate static func fo(_ arr: [Int]) -> [Int] {
        log(message: "[TypingDNA] Filtering outliers { arr: %@ }", level: 3, arr.debugDescription);
        let arr = arr.map({Double($0)});
        let rarr = fo(arr);
        let returnArr = rarr.map({Int($0)});
        log(message: "[TypingDNA] Outliers filtered { returnArr: %@ }", level: 3, returnArr.debugDescription);
        return returnArr;
    }
    
    // Target functions
    @objc
    fileprivate static func isTarget(_ target:String) -> Bool {
        log(message: "[TypingDNA] Is target { target: %@ }", level: 2, target);
        if (lastTarget == target && lastTargetFound) {
            log(message: "[TypingDNA] Is a target", level: 2);
            return true;
        } else {
            let targetLength = targetIds.count;
            var targetFound = false;
            if (targetLength > 0) {
                for i in 0..<targetLength {
                    if (targetIds[i] == target) {
                        targetFound = true;
                        break;
                    }
                }
                lastTarget = target;
                lastTargetFound = targetFound;
                log(message: "[TypingDNA] Target found? { tragetFound: %d }", level: 2, targetFound);
                return targetFound;
            } else {
                lastTarget = target;
                lastTargetFound = true;
                log(message: "[TypingDNA] Is a target", level: 2);
                return true;
            }
        }
    }
    
    @objc
    fileprivate static func sliceStackByTargetId(_ stack:[[Any]], _ targetId:String) -> [[Any]] {
        log(message: "[TypingDNA] Slice stack by target id { stack %@, targetId: %@ }", level: 2, stack.debugDescription, targetId);
        let length = stack.count;
        var newStack = [[Any]]();
        for i in 0..<length {
            var arr:[Any] = stack[i];
            if (arr[5] as! String == targetId) {
                newStack.append(arr);
            }
        }
        log(message: "[TypingDNA] Sliced stack { newStack: %@ }", level: 2, newStack.debugDescription);
        return newStack;
    }
    
    // Math functions
    
    fileprivate static func rd(_ value: Double, _ places: Int) -> Double {
        let decimalValue:Double = pow(10, Double(places));
        return round(value * decimalValue) / decimalValue;
    }
    fileprivate static func rd(_ value: Double) -> Double {
        return rd(value, 4);
    }
    
    fileprivate static func avg(_ arr: [Double]) -> Double {
        let len:Double = Double(arr.count);
        var sum:Double = 0;
        for num in arr {
            sum += num;
        }
        return rd(sum/len, 4);
    }
    fileprivate static func avg(_ intArr: [Int]) -> Double {
        return avg(intArr.map({Double($0)}));
    }
    
    fileprivate static func sd(_ arr: [Double]) -> Double {
        let len = arr.count;
        if (len < 2) {
            return 0;
        } else {
            var sumVS:Double = 0;
            let mean:Double = avg(arr);
            for num in arr {
                let numd = Double(num) - mean;
                sumVS += numd*numd;
            }
            return sqrt(sumVS/Double(len));
        }
    }
    fileprivate static func sd(_ arr: [Int]) -> Double {
        return sd(arr.map({Double($0)}));
    }
    
    // Mobile only
    
    // Device motion.
    
    fileprivate static var motion = CMMotionManager();
    fileprivate static var motionStarted = false;
    fileprivate static var accQueue = OperationQueue();
    fileprivate static var gyroQueue = OperationQueue();
    fileprivate static var motionQueue = OperationQueue();
    fileprivate static var resetAccData = false;
    fileprivate static var resetGyroData = false;
    fileprivate static var kpAccZ:[Int] = [];
    fileprivate static var kpX:[Int] = [];
    fileprivate static var kpY:[Int] = [];
    fileprivate static var kpTimes:[Int] = [];
    fileprivate static var kpLastZ = 0;
    fileprivate static var kpLastAccX = 0;
    fileprivate static var kpLastAccY = 0;
    fileprivate static var kpLastPitch = 0;
    fileprivate static var kpLastRoll = 0;
    fileprivate static var kpLastAccZ = 0;
    
    @objc
    static public func startRecordMotion() {
        log(message: "[TypingDNA] Starting motion recording...", level: 2);
        let interval = 1.0 / 60.0; // Hz
        accQueue.maxConcurrentOperationCount = 2;
        gyroQueue.maxConcurrentOperationCount = 2;
        motionQueue.maxConcurrentOperationCount = 2;
        if motion.isAccelerometerAvailable {
            motion.accelerometerUpdateInterval = interval;
            motion.startAccelerometerUpdates(to: self.accQueue, withHandler: { (data, error) in
                if let dataA = data {
                    if(resetAccData) {
                        log(message: "[TypingDNA] Resetting accelerometer data...", level: 2);
                        kpAccZ.removeAll();
                        kpTimes.removeAll();
                        resetAccData = false;
                    } else {
                        kpTimes.append(self.getTime());
                        let kpCurAccX = -Int(1000*Double(dataA.acceleration.x));
                        let kpCurAccY = -Int(1000*Double(dataA.acceleration.y));
                        let kpCurAccZ = -Int(1000*Double(dataA.acceleration.z));
                        kpLastAccX = kpCurAccX;
                        kpLastAccY = kpCurAccY;
                        kpLastAccZ = kpCurAccZ;
                        kpAccZ.append(kpCurAccZ);
                        if (kpAccZ.count > 21) {
                            kpAccZ.remove(at: 0);
                        }
                        if (kpTimes.count > 21) {
                            kpTimes.remove(at: 0);
                        }
                        
                        let pitch = atan2(Float(-kpCurAccY), sqrt(Float(kpCurAccX * kpCurAccX + kpCurAccZ * kpCurAccZ))) * 180 / Float.pi;
                        let roll = atan2(Float(-kpCurAccX), sqrt(Float(kpCurAccY * kpCurAccY + kpCurAccZ * kpCurAccZ))) * 180 / Float.pi;
                        kpLastPitch = Int(pitch * 10);
                        kpLastRoll = Int(roll * 10);
                    }
                }
            });
        }
        if motion.isGyroAvailable {
            motion.gyroUpdateInterval = interval;
            motion.startGyroUpdates(to: self.gyroQueue, withHandler: { (data, error) in
                if let dataG = data {
                    if(resetGyroData) {
                        log(message: "[TypingDNA] Resetting gyroscope data...", level: 2);
                        kpX.removeAll();
                        kpY.removeAll();
                        resetGyroData = false;
                    } else {
                        let kpCurX = Int(573*Double(dataG.rotationRate.x));
                        let kpCurY = Int(573*Double(dataG.rotationRate.y));
                        let kpCurZ = Int(573*Double(dataG.rotationRate.z));
                        kpX.append(kpCurX);
                        kpY.append(kpCurY);
                        kpLastZ = kpCurZ;
                        if (kpX.count > 21) {
                            kpX.remove(at: 0);
                        }
                        if (kpY.count > 21) {
                            kpY.remove(at: 0);
                        }
                    }
                }
            });
        }
        motionStarted = true;
    }
    
    @objc
    static public func stopRecordMotion() {
        log(message: "[TypingDNA] Stopping motion recording...", level: 2);
        if motion.isAccelerometerAvailable {
            motion.stopAccelerometerUpdates();
        }
        if motion.isGyroAvailable {
            motion.stopGyroUpdates();
        }
        if motion.isDeviceMotionAvailable {
            motion.stopDeviceMotionUpdates();
        }
        motionStarted = false;
    }
    
    @objc
    static public func getDeviceMotion(_ full: Bool) -> [Int] {
        log(message: "[TypingDNA] Getting device motion { full: %d }", level: 2, full);
        if (!motionStarted) {
            log(message: "[TypingDNA] Device motion wasn't started...", level: 2);
            startRecordMotion();
        }
        var returnArr:[Int] = [];
        var kpCurAccX = 0, kpCurAccY = 0, kpCurAccZ = 0;
        if let dataA = motion.accelerometerData {
            returnArr.append(-Int(1000*Double(dataA.acceleration.x)));
            returnArr.append(-Int(1000*Double(dataA.acceleration.y)));
            returnArr.append(-Int(1000*Double(dataA.acceleration.z)));
            
            kpCurAccX = -Int(1000*Double(dataA.acceleration.x));
            kpCurAccY = -Int(1000*Double(dataA.acceleration.y));
            kpCurAccZ = -Int(1000*Double(dataA.acceleration.z));
        } else {
            returnArr.append(0);
            returnArr.append(0);
            returnArr.append(0);
        }
        if let dataG = motion.gyroData {
            returnArr.append(Int(573*Double(dataG.rotationRate.x)));
            returnArr.append(Int(573*Double(dataG.rotationRate.y)));
            returnArr.append(Int(573*Double(dataG.rotationRate.z)));
        } else {
            returnArr.append(0);
            returnArr.append(0);
            returnArr.append(0);
        }
        if (full) {
            let pitch = atan2(Float(-kpCurAccY), sqrt(Float(kpCurAccX * kpCurAccX + kpCurAccZ * kpCurAccZ))) * 180 / Float.pi;
            let roll = atan2(Float(-kpCurAccX), sqrt(Float(kpCurAccY * kpCurAccY + kpCurAccZ * kpCurAccZ))) * 180 / Float.pi;
            returnArr.append(Int(pitch * 10));
            returnArr.append(Int(roll * 10));
        }
        log(message: "[TypingDNA] Device motion { returnArr: %@ }", level: 2, returnArr.debugDescription);
        return returnArr;
    }
    
    @objc
    fileprivate static func kpADifArr(_ arr:[Int]) -> [[Int]] {
        log(message: "[TypingDNA] kpADiffArr { arr: %@ }", level: 3, arr.debugDescription);
        let length = arr.count - 1;
        var firstArr:[Int] = [0];
        if (length < 2) {
            log(message: "[TypingDNA] kpADiffArr empty...", level: 3);
            return [[0],[0]];
        }
        var newArr:[Int] = [];
        var returnArr:[Int] = [];
        for i in 0..<length {
            let newVal = arr[i + 1] - arr[i];
            firstArr.append(newVal);
        }
        for i in 0..<length {
            let newVal = firstArr[i + 1] - firstArr[i];
            newArr.append(newVal);
            returnArr.append(abs(newVal));
        }
        log(message: "[TypingDNA] kpADiffArr { newArr: %@, returnArr: %@ }", level: 3, newArr.debugDescription, returnArr.debugDescription);
        return [newArr, returnArr];
    }
    
    @objc
    fileprivate static func kpRDifArr(_ arr:[Int]) -> [[Int]] {
        log(message: "[TypingDNA] kpRDifArr { arr: %@ }", level: 3, arr.debugDescription);
        let length = arr.count - 2;
        var firstArr:[Int] = [];
        if (length < 0) {
            log(message: "[TypingDNA] kpRDifArr empty...", level: 3);
            return [[0],[0]];
        }
        var localMax = 0;
        var localMin = 0;
        var posMax = 0;
        var posMin = 0;
        if (length > 0) {
            for i in 0..<length {
                let newVal = arr[i + 1] - arr[i];
                firstArr.append(newVal);
                if (newVal >= localMax) {
                    localMax = newVal;
                    posMax = i;
                } else if (newVal <= localMin) {
                    localMin = newVal;
                    posMin = i;
                }
            }
        } else {
            let newVal = arr[1] - arr[0];
            firstArr.append(newVal);
        }
        let returnArr:[Int] = [posMax-1, posMax, posMax+1, posMax+2, posMax+3, posMin-1, posMin, posMin+1, posMin+2, posMin+3];
        log(message: "[TypingDNA] kpRDifArr { firstArr: %@, returnArr: %@ }", level: 3, firstArr.debugDescription, returnArr.debugDescription);
        return [firstArr, returnArr];
    }
    
    @objc
    fileprivate static func kpGetAll() -> [Any] {
        log(message: "[TypingDNA] kpGetAll called...", level: 3);
        var _kpAccZ = kpAccZ;
        var _kpTimes = kpTimes;
        var _kpX = kpX;
        var _kpY = kpY;
        if (_kpAccZ.count < 2) {
            let returnVal = (KIOSlastPressTime >= KIOSlast2ReleaseTime) ? KIOSlastPressTime : 0;
            let returnMotionArr = getDeviceMotion(true).map({String(describing:$0)})
            let returnMotionStr = returnMotionArr.joined(separator: ",");
            log(message: "[TypingDNA] kpGetAll { return: %@ }", level: 3, [returnVal, returnMotionStr, "0", "0", "0"].debugDescription);
            return [returnVal, returnMotionStr, "0", "0", "0"];
        } else {
            let kpZA2 = kpADifArr(_kpAccZ);
            let kpXR2 = kpRDifArr(_kpX);
            let kpYR2 = kpRDifArr(_kpY);
            let kpza = kpZA2[0];
            let kpzaAbs = kpZA2[1];
            let kpXR = kpXR2[0];
            let kpxPos = kpXR2[1];
            let kpYR = kpYR2[0];
            let kpyPos = kpYR2[1];
            if (_kpX.count > 2) {
                _kpX.remove(at: 0);
            }
            if (_kpY.count > 2) {
                _kpY.remove(at: 0);
            }
            if (_kpAccZ.count > 2) {
                _kpAccZ.remove(at: 0);
            }
            if (_kpTimes.count > 2) {
                _kpTimes.remove(at: 0);
            }
            var returnVal = (KIOSlastPressTime >= KIOSlast2ReleaseTime) ? KIOSlastPressTime : 0;
            if (pressWorks == false) {
                var kpPos:[Int] = [];
                kpPos.append(contentsOf: kpxPos);
                kpPos.append(contentsOf: kpyPos);
                kpPos = kpPos.sorted();
                var kpxyPos:[Int] = [];
                for i in 1..<kpPos.count {
                    if (kpPos[i] != kpPos[i-1]) {
                        kpxyPos.append(kpPos[i]);
                    }
                }
                var lastKpza = 0;
                var lastKpTime = _kpTimes[_kpTimes.count-1];
                for i in 0..<kpxyPos.count {
                    let j = kpxyPos[i];
                    let minj = (kpzaAbs.count > 8) ? 2 : ((kpzaAbs.count > 4) ? 1 : 0);
                    if (j > minj && kpzaAbs.count > j && kpzaAbs[j] > lastKpza) {
                        lastKpza = kpzaAbs[j];
                        lastKpTime = _kpTimes[j];
                    }
                }
                returnVal = lastKpTime;
            } else {
                KIOSlastPressTime = 0;
            }
            let kpAccZ_last = (_kpAccZ.last != nil) ? _kpAccZ.last : 0;
            let kpX_last = (_kpX.last != nil) ? _kpX.last : 0;
            let kpY_last = (_kpY.last != nil) ? _kpY.last : 0;
            let returnMotion = [kpLastAccX, kpLastAccY, kpAccZ_last, kpX_last, kpY_last, kpLastZ, kpLastPitch, kpLastRoll];
            resetAccData = true;
            resetGyroData = true;
            let kp0arr = returnMotion.map({String(describing:$0!)});
            let kp1arr = kpza.map({String(describing:$0)});
            let kp2arr = kpXR.map({String(describing:$0)});
            let kp3arr = kpYR.map({String(describing:$0)});
            let kp0 = kp0arr.joined(separator: ",");
            let kp1 = kp1arr.joined(separator: ",");
            let kp2 = kp2arr.joined(separator: ",");
            let kp3 = kp3arr.joined(separator: ",");
            log(message: "[TypingDNA] kpGetAll { return: %@ }", level: 3, [returnVal, kp0, kp1, kp2, kp3].debugDescription);
            return [returnVal, kp0, kp1, kp2, kp3];
        }
    }
    
    // KIOS = Keyboard iOS workaround
    
    static var KIOScurrentResponder = UITextField();
    static var KIOSdidSetup = false;
    static var KIOSlastPressTime:Int = 0;
    static var KIOSlastReleaseTime:Int = 0;
    static var KIOSlast2ReleaseTime:Int = 0;
    static var KIOSkeyboardOn = false;
    static var KIOSlastText: Dictionary<String, String> = [:];
    static var KIOSlastTimeStamp:String = "";
    static var KIOSlastDeviceMotionArr:[Int] = [];
    static var KIOSpointX = -1;
    static var KIOSpointY = -1;
    static var pressWorks = false;
    
    
    @objc
    static public func KIOSkeyPressed(_ point:CGPoint) {
        log(message: "[TypingDNA] Key pressed { KIOSkeyboardOn: %d }", level: 2, KIOSkeyboardOn);
        if (KIOSkeyboardOn) {
            let time = getTime();
            if (time != KIOSlastPressTime) {
                KIOSlastPressTime = time;
                KIOSlastText.updateValue(String(describing: KIOScurrentResponder.text!), forKey: String(KIOScurrentResponder.hash));
                KIOSpointX = Int(Double(point.x));
                KIOSpointY = Int(Double(point.y));
                log(message: "[TypingDNA] Key pressed info { lastPressTime: %d, lastText: %@, x: %d, y: %d }", level: 2, KIOSlastPressTime, KIOSlastText, KIOSpointX, KIOSpointY);
                if (!pressWorks) {
                    pressWorks = true;
                }
            }
        }
    }
    
    @objc
    static public func KIOSkeyReleased(_ target:String) {
        log(message: "[TypingDNA] Key released { target: %@ }", level: 2, target);
        let time = getTime();
        if (time != KIOSlastReleaseTime) {
            KIOSlast2ReleaseTime = KIOSlastReleaseTime;
            KIOSlastReleaseTime = time;
            let currentText = String(describing: KIOScurrentResponder.text!);
            if (currentText.count - 1 != KIOSlastText[target]?.count ?? 0) {
                //print("delete/backspace/swap");
                KIOSlastText.updateValue(currentText, forKey: target);
                log(message: "[TypingDNA] No text change { KIOSlastText: %@ }", level: 2, KIOSlastText[target] ?? "");
                return;
            }
            KIOSlastText.updateValue(currentText, forKey: target);
            if (KIOSgetCharacterBeforeCursor() != nil) {
                let currentChar = String(describing: KIOSgetCharacterBeforeCursor()!);
                let currentCharUp = currentChar.uppercased();
                let s = currentChar.unicodeScalars;
                let keyChar = Int(s[s.startIndex].value);
                let sup = currentCharUp.unicodeScalars;
                let keyCode = Int(sup[sup.startIndex].value);
                if (keyCode == 65039 || keyCode == 65533) {
                    //print("emoji");
                    log(message: "[TypingDNA] Got emoji", level: 2);
                    return;
                }
                drkc[lastPressedKey] = keyChar;
                let modifiers = false; // ignore modifiers for mobile (works with modifiers too but useless)
                let kpGet = kpGetAll();
                let xy = String(KIOSpointX) + "," + String(KIOSpointY);
                keyReleased(keyCode, keyChar, modifiers, KIOSlastReleaseTime, target, kpGet, xy);
            } else {
                log(message: "[TypingDNA] Character before cursor is nil", level: 2);
                return;
            }
        }
    }
    
    @objc
    static public func KIOSgetCharacterBeforeCursor() -> String? {
        let textField = KIOScurrentResponder;
        if let cursorRange = textField.selectedTextRange {
            if let newPosition = textField.position(from: cursorRange.start, offset: -1) {
                let range = textField.textRange(from: newPosition, to: cursorRange.start)
                let charactersBeforeCursor = textField.text(in: range!);
                log(message: "[TypingDNA] Characters before cursor { return: %@ }", level: 2, charactersBeforeCursor ?? "nil");
                return textField.text(in: range!)
            }
        }
        log(message: "[TypingDNA] Characters before cursor { return: %@ }", level: 2, "nil");
        return nil
    }
    
    @objc
    static func UIW_KIOSkeyReleased(_ sender: UITextField) {
        let targetHash = String(sender.hash);
        log(message: "[TypingDNA] KIOSkeyReleased sender { hash: %@, text: %@ }", level: 2, targetHash, sender.text ?? "");
        KIOScurrentResponder = sender;
        KIOSkeyReleased(targetHash);
        KIOSlastText.updateValue(String(describing: sender.text!), forKey: targetHash);
    }
}

// UIWindow extension for catching iOS press/release events.
extension UIWindow {
    
    override open func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event);
        if (!RNTypingDNARecorderMobile.KIOSdidSetup) {
            RNTypingDNARecorderMobile.log(message: "[TypingDNA] KIOS did setup", level: 1);
            NotificationCenter.default.addObserver(self, selector: #selector(self.UIW_KIOSkeyboardDidShow(_:)), name: UIResponder.keyboardDidShowNotification, object: nil);
            NotificationCenter.default.addObserver(self, selector: #selector(self.UIW_KIOSkeyboardDidHide(_:)), name: UIResponder.keyboardDidHideNotification, object: nil);
            RNTypingDNARecorderMobile.KIOSdidSetup = true;
        }
        if (event != nil) {
            let time = String(event!.timestamp);
            if (time != RNTypingDNARecorderMobile.KIOSlastTimeStamp) {
                RNTypingDNARecorderMobile.KIOSkeyPressed(point);
                RNTypingDNARecorderMobile.KIOSlastTimeStamp = time;
            }
        }
        return view == self ? nil : view;
    }
    
    @objc func UIW_KIOSkeyboardDidShow(_ notification: NSNotification) {
        RNTypingDNARecorderMobile.startRecordMotion();
        RNTypingDNARecorderMobile.KIOSkeyboardOn = true;
    }
    
    @objc func UIW_KIOSkeyboardDidHide(_ notification: NSNotification) {
        RNTypingDNARecorderMobile.stopRecordMotion();
        RNTypingDNARecorderMobile.KIOSkeyboardOn = false;
    }
}


extension UIDevice {
    var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
}