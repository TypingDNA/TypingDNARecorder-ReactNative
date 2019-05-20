
package com.typingdna;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.Callback;

public class RNTypingdnarecorderModule extends ReactContextBaseJavaModule {

  private final ReactApplicationContext reactContext;
  private RNTypingDNARecorderMobile tdna;

  public RNTypingdnarecorderModule(ReactApplicationContext reactContext) {
    super(reactContext);
    this.reactContext = reactContext;
  }

  @Override
  public String getName() {
    return "RNTypingdnarecorder";
  }

  @ReactMethod
  public void initialize() {
    tdna = new RNTypingDNARecorderMobile(getCurrentActivity());
  }

  @ReactMethod
  public void start() {
    tdna.start();
  }

  @ReactMethod
  public void stop() {
    tdna.stop();
  }

  @ReactMethod
  public void reset() {
    tdna.reset();
  }

  @ReactMethod
  public void pause() {
    tdna.pause();
  }

  @ReactMethod
  public void addTarget(Integer targetId) {
    tdna.addTarget((int) targetId);
  }

  @ReactMethod
  public void removeTarget(Integer targetId) {
    tdna.removeTarget((int) targetId);
  }

  @ReactMethod
  public void getTypingPattern(Integer type, Integer length, String text, Integer textId, Integer targetId, Boolean caseSensitive, Callback callback) {
    callback.invoke(tdna.getTypingPattern(type, length, text, textId, targetId, caseSensitive));
  }
}