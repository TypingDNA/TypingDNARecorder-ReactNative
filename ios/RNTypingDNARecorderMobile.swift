//
//  RNTypingDNARecorderMobile.swift iOS version
//  tdnaIOS
//
//  TypingDNA - Typing Biometrics Recorder Mobile iOS
//  https://www.typingdna.com
//
//
//  @version 3.0
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

/**
 * Instantiate RNTypingDNARecorderMobile class in your project and make sure you also add UIViewExtention to your project
 */

// DO NOT MODIFY
open class RNTypingDNARecorderMobile {
    
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
    static let version = 3.0;
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
    fileprivate static var screenWidth = UIScreen.main.bounds.width;
    fileprivate static var screenHeight = UIScreen.main.bounds.height;
    fileprivate static var initialized = false;
    static var kpTimer:Timer = Timer();
    
    
    public init() {
        if (!RNTypingDNARecorderMobile.initialized) {
            RNTypingDNARecorderMobile.initialized = RNTypingDNARecorderMobile.initialize();
        }
    }
    
    static public func initialize() -> Bool {
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
    static public func getTypingPattern(type:Int, length:Int, text:String, textId:Int, target:UITextField?, caseSensitive:Bool) -> String {
        if (type == 1) {
            return getDiagram(false, text, textId, length, target, caseSensitive);
        } else if (type == 2) {
            return getDiagram(true, text, textId, length, target, caseSensitive);
        } else {
            return get(length).replacingOccurrences(of: ".0,", with: ",");
        }
    }
    
    static public func getTypingPattern(_ type:Int, _ length:Int, _ text:String, _ textId:Int, _ target:UITextField?, _ caseSensitive:Bool) -> String {
        return getTypingPattern(type:type, length:length, text:text, textId:textId, target:target, caseSensitive:caseSensitive);
    }
    
    static public func getTypingPattern(_ type:Int, _ length:Int, _ text:String, _ textId:Int, _ target:UITextField?) -> String {
        return getTypingPattern(type:type, length:length, text:text, textId:textId, target:target, caseSensitive:false);
    }
    
    static public func getTypingPattern(_ type:Int, _ length:Int, _ text:String, _ textId:Int) -> String {
        return getTypingPattern(type:type, length:length, text:text, textId:textId, target:nil, caseSensitive:false);
    }
    
    /**
     * Resets the history stack of recorded typing events (and mouse if all:true).
     */
    static public func reset(_ all: Bool) {
        historyStack = [[Int]]();
        stackDiagram = [[Int]]();
        pt1 = getTime();
        ut1 = getTime();
    }
    static public func reset() {
        reset(false);
    }
    
    /**
     * Automatically called at initialization. It starts the recording of typing
     * events. You only have to call .start() to resume recording after a .stop()
     */
    static public func start() {
        recording = true;
        diagramRecording = true;
    }
    
    /**
     * Ends the recording of further typing events.
     */
    static public func stop() {
        recording = false;
        diagramRecording = false;
    }
    
    /**
     * Adds a target to the targetIds array.
     */
    static public func addTarget(_ targetField:UITextField) {
        let target = String(targetField.hashValue);
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
            }
        } else {
            targetIds.append(target);
        }
    }
    
    /**
     * Adds a target to the targetIds array.
     */
    static public func removeTarget(_ targetField:UITextField) {
        let target = String(targetField.hashValue);
        let targetLength = targetIds.count;
        if (targetLength > 0) {
            for i in 0..<targetLength {
                if (targetIds[i] == target) {
                    targetIds.remove(at: i);
                    break;
                }
            }
        }
    }
    
    static public func keyReleased(_ keyCode: Int, _ keyChar: Int, _ modifiers: Bool, _ upTime:Int, _ target:String, _ kpGet:[Any], _ xy:String) {
        if ((!recording && !diagramRecording) || keyCode >= maxKeyCode) {
            return;
        }
        if (!isTarget(target)) {
            return;
        }
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
    
    static public func fnv1a(_ str: String) -> String {
        return String(fnv1a_32(bytes: str.utf8));
    }
    
    // Private functions
    
    fileprivate static func getSpecialKeys() -> String {
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
            return returnStrArr.joined(separator: ",");
        } else {
            return "0,-1,-1,0,-1,-1,0,-1,-1,0,-1,-1,0,-1,-1";
        }
    }
    
    fileprivate static func historyAdd(_ arr: [Any]) {
        historyStack.append(arr);
        if (historyStack.count > maxHistoryLength) {
            historyStack.remove(at: 0);
        }
    }
    
    fileprivate static func historyAddDiagram(_ arr: [Any]) {
        stackDiagram.append(arr);
    }
    
    fileprivate static func getSeek(_ length: Int) -> [Int] {
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
        return seekArr;
    }
    
    fileprivate static func getPress(_ length: Int) -> [Int] {
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
        return returnStr;
    }
    
    fileprivate static func get(_ length: Int) -> String {
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
            arr.append("0"); // strLength/histRev
            arr.append(getSpecialKeys());
            arr.append(getDeviceSignature());
            let typingPattern:String = arr.joined(separator: ",");
            return typingPattern;
        } else {
            return "";
        }
    }
    
    static public func getDeviceSignature() -> String {
        let deviceType = 2; // {0:unknown, 1:pc, 2:phone, 3:tablet}
        let deviceModel = 0; // fnv1aHash of device manufacturer + "-" + model
        let deviceId = 0; // fnv1aHash of device id
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
        let orientation = (screenWidth > screenHeight) ? 2 : 1; // {0:unknown, 1:portrait, 2:landscape}
        let osVersion = Int(String(ProcessInfo.processInfo.operatingSystemVersion.majorVersion) + String(ProcessInfo.processInfo.operatingSystemVersion.minorVersion))!; // numbers only
        let browserVersion = 0; // numbers only
        let cookieId = 0; // only in iframe
        
        let signatureArr:[String] = [deviceType,deviceModel,deviceId,isMobile,operatingSystem,programmingLanguage,systemLanguage,isTouchDevice,pressType,keyboardInput,keyboardType,pointerInput,browserType,displayWidth,displayHeight,orientation,osVersion,browserVersion,cookieId].map({String(describing: $0)});
        let signatureStr = signatureArr.joined(separator: "-");
        let signature:String = fnv1a(signatureStr); // fnv1aHash of all above!
        
        let returnArr:[String] = [deviceType,deviceModel,deviceId,isMobile,operatingSystem,programmingLanguage,systemLanguage,isTouchDevice,pressType,keyboardInput,keyboardType,pointerInput,browserType,displayWidth,displayHeight,orientation,osVersion,browserVersion,cookieId,signature].map({String(describing: $0)});
        let returnStr = returnArr.joined(separator: ",");
        return returnStr;
    }
    
    static public func getTime() -> Int{
        return Int(CACurrentMediaTime()*1000);
    }
    
    // Filter outliers
    fileprivate static func fo(_ arr: [Double]) -> [Double] {
        if (arr.count < 1) {
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
        return fVal;
    }
    fileprivate static func fo(_ arr: [Int]) -> [Int] {
        let arr = arr.map({Double($0)});
        let rarr = fo(arr);
        return rarr.map({Int($0)});
    }
    
    // Target functions
    
    fileprivate static func isTarget(_ target:String) -> Bool {
        if (lastTarget == target && lastTargetFound) {
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
                return targetFound;
            } else {
                lastTarget = target;
                lastTargetFound = true;
                return true;
            }
        }
    }
    
    fileprivate static func sliceStackByTargetId(_ stack:[[Any]], _ targetId:String) -> [[Any]] {
        let length = stack.count;
        var newStack = [[Any]]();
        for i in 0..<length {
            var arr:[Any] = stack[i];
            if (arr[5] as! String == targetId) {
                newStack.append(arr);
            }
        }
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
    fileprivate static func avg(_ arr: [Int]) -> Double {
        return avg(arr.map({Double($0)}));
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
    
    
    static public func startRecordMotion() {
        let interval = 1.0 / 60.0; // Hz
        accQueue.maxConcurrentOperationCount = 2;
        gyroQueue.maxConcurrentOperationCount = 2;
        motionQueue.maxConcurrentOperationCount = 2;
        if motion.isAccelerometerAvailable {
            motion.accelerometerUpdateInterval = interval;
            motion.startAccelerometerUpdates(to: self.accQueue, withHandler: { (data, error) in
                if let dataA = data {
                    if(resetAccData) {
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
                    }
                }
            });
        }
        if motion.isGyroAvailable {
            motion.gyroUpdateInterval = interval;
            motion.startGyroUpdates(to: self.gyroQueue, withHandler: { (data, error) in
                if let dataG = data {
                    if(resetGyroData) {
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
        if motion.isDeviceMotionAvailable {
            motion.deviceMotionUpdateInterval = interval;
            motion.startDeviceMotionUpdates(to: self.motionQueue, withHandler: { (data, error) in
                if let dataM = data {
                    let pitch:Double = 100*Double(dataM.attitude.pitch);
                    let roll:Double = 100*Double(dataM.attitude.roll);
                    kpLastRoll = Int(5.625 * roll);
                    var beta = Int(5.625 * pitch);
                    if (abs(kpLastRoll) > 900) {
                        beta = ((beta > 0) ? 1800 : -1800) - beta;
                    }
                    kpLastPitch = beta;
                }
            });
        }
        motionStarted = true;
    }
    
    static public func stopRecordMotion() {
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
    
    static public func getDeviceMotion(_ full: Bool) -> [Int] {
        if (!motionStarted) {
            startRecordMotion();
        }
        var returnArr:[Int] = [];
        if let dataA = motion.accelerometerData {
            returnArr.append(-Int(1000*Double(dataA.acceleration.x)));
            returnArr.append(-Int(1000*Double(dataA.acceleration.y)));
            returnArr.append(-Int(1000*Double(dataA.acceleration.z)));
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
            if let dataM = motion.deviceMotion {
                let pitch:Double = 100*Double(dataM.attitude.pitch);
                let roll:Double = 100*Double(dataM.attitude.roll);
                let gamma = Int(5.625 * roll);
                var beta = Int(5.625 * pitch);
                if (abs(gamma) > 900) {
                    beta = ((beta > 0) ? 1800 : -1800) - beta;
                }
                returnArr.append(beta);
                returnArr.append(gamma);
            } else {
                returnArr.append(0);
                returnArr.append(0);
            }
        }
        return returnArr;
    }
    
    fileprivate static func kpADifArr(_ arr:[Int]) -> [[Int]] {
        let length = arr.count - 1;
        var firstArr:[Int] = [0];
        if (length < 2) {
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
        return [newArr, returnArr];
    }
    
    fileprivate static func kpRDifArr(_ arr:[Int]) -> [[Int]] {
        let length = arr.count - 2;
        var firstArr:[Int] = [];
        if (length < 0) {
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
        return [firstArr, returnArr];
    }
    
    fileprivate static func kpGetAll() -> [Any] {
        var _kpAccZ = kpAccZ;
        var _kpTimes = kpTimes;
        var _kpX = kpX;
        var _kpY = kpY;
        if (_kpAccZ.count < 2) {
            let returnVal = (KIOSlastPressTime >= KIOSlast2ReleaseTime) ? KIOSlastPressTime : 0;
            let returnMotionArr = getDeviceMotion(true).map({String(describing:$0)})
            let returnMotionStr = returnMotionArr.joined(separator: ",");
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
    static var KIOSlastText = "";
    static var KIOSlastTimeStamp:String = "";
    static var KIOSlastDeviceMotionArr:[Int] = [];
    static var KIOSpointX = -1;
    static var KIOSpointY = -1;
    static var pressWorks = false;
    
    
    static public func KIOSkeyPressed(_ point:CGPoint) {
        if (KIOSkeyboardOn) {
            let time = getTime();
            if (time != KIOSlastPressTime) {
                KIOSlastPressTime = time;
                KIOSlastText = String(describing: KIOScurrentResponder.text!);
                KIOSpointX = Int(Double(point.x));
                KIOSpointY = Int(Double(point.y));
                if (!pressWorks) {
                    pressWorks = true;
                }
            }
        }
    }
    
    static public func KIOSkeyReleased(_ target:String) {
        let time = getTime();
        if (time != KIOSlastReleaseTime) {
            KIOSlast2ReleaseTime = KIOSlastReleaseTime;
            KIOSlastReleaseTime = time;
            let currentText = String(describing: KIOScurrentResponder.text!);
            if (currentText.count - 1 != KIOSlastText.count) {
                //print("delete/backspace/swap");
                KIOSlastText = currentText;
                return;
            }
            KIOSlastText = currentText;
            if (KIOSgetCharacterBeforeCursor() != nil) {
                let currentChar = String(describing: KIOSgetCharacterBeforeCursor()!);
                let currentCharUp = currentChar.uppercased();
                let s = currentChar.unicodeScalars;
                let keyChar = Int(s[s.startIndex].value);
                let sup = currentCharUp.unicodeScalars;
                let keyCode = Int(sup[sup.startIndex].value);
                if (keyCode == 65039 || keyCode == 65533) {
                    //print("emoji");
                    return;
                }
                drkc[lastPressedKey] = keyChar;
                let modifiers = false; // ignore modifiers for mobile (works with modifiers too but useless)
                let kpGet = kpGetAll();
                let xy = String(KIOSpointX) + "," + String(KIOSpointY);
                keyReleased(keyCode, keyChar, modifiers, KIOSlastReleaseTime, target, kpGet, xy);
            } else {
                return;
            }
        }
    }
    
    static public func KIOSgetCharacterBeforeCursor() -> String? {
        let textField = KIOScurrentResponder;
        if let cursorRange = textField.selectedTextRange {
            if let newPosition = textField.position(from: cursorRange.start, offset: -1) {
                let range = textField.textRange(from: newPosition, to: cursorRange.start)
                return textField.text(in: range!)
            }
        }
        return nil
    }
    
}

// UIWindow extension for catching iOS press/release events.

extension UIWindow {
    
    override open func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event);
        if (!RNTypingDNARecorderMobile.KIOSdidSetup) {
            NotificationCenter.default.addObserver(self, selector: #selector(self.UIW_KIOSkeyboardDidShow(_:)), name: UIResponder.keyboardDidShowNotification, object: nil);
            NotificationCenter.default.addObserver(self, selector: #selector(self.UIW_KIOSkeyboardDidHide(_:)), name: UIResponder.keyboardDidHideNotification, object: nil);
            RNTypingDNARecorderMobile.KIOSdidSetup = true;
        }
        if (event != nil) {
            let time = String(event!.timestamp);
            if (time != RNTypingDNARecorderMobile.KIOSlastTimeStamp) {
                RNTypingDNARecorderMobile.KIOSkeyPressed(point);
                UIW_KIOSsetResponder();
                RNTypingDNARecorderMobile.KIOSlastTimeStamp = time;
            }
        }
        return view == self ? nil : view;
    }
    
    @objc func UIW_KIOSkeyboardDidShow(_ notification: NSNotification) {
        UIW_KIOSsetResponder();
        RNTypingDNARecorderMobile.startRecordMotion();
        RNTypingDNARecorderMobile.KIOSkeyboardOn = true;
    }
    
    @objc func UIW_KIOSkeyboardDidHide(_ notification: NSNotification) {
        RNTypingDNARecorderMobile.stopRecordMotion();
        RNTypingDNARecorderMobile.KIOSkeyboardOn = false;
    }
    
    @objc func UIW_KIOSkeyReleased(_ sender: UITextInput) {
        let targetHash = String(sender.hash);
        RNTypingDNARecorderMobile.KIOSkeyReleased(targetHash);
    }
    
    @objc func UIW_KIOSsetResponder() {
        if let x = UIResponder.current as? UITextField {
            if x != RNTypingDNARecorderMobile.KIOScurrentResponder {
                RNTypingDNARecorderMobile.KIOScurrentResponder = x;
                RNTypingDNARecorderMobile.KIOSlastText = String(describing: x.text!);
                RNTypingDNARecorderMobile.KIOScurrentResponder.removeTarget(nil, action: nil, for: .editingChanged);
                RNTypingDNARecorderMobile.KIOScurrentResponder.addTarget(self, action: #selector(UIW_KIOSkeyReleased(_:)), for: .editingChanged);
            }
        }
    }
}

// UIResponder extension. Returns current responder when asked from extended UIWindow.

extension UIResponder {
    
    private weak static var _currentFirstResponder: UIResponder? = nil
    
    public static var current: UIResponder? {
        UIResponder._currentFirstResponder = nil
        UIApplication.shared.sendAction(#selector(findFirstResponder(sender:)), to: nil, from: nil, for: nil)
        return UIResponder._currentFirstResponder
    }
    
    @objc internal func findFirstResponder(sender: AnyObject) {
        UIResponder._currentFirstResponder = self
    }
}


