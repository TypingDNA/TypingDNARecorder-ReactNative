
# typingdnarecorder-react-native

## Getting started

`$ npm install typingdnarecorder-react-native --save`

### Mostly automatic installation (not recommended)

`$ react-native link typingdnarecorder-react-native`

### Manual installation


#### iOS

1. In XCode, in the project navigator, right click `Libraries` ➜ `Add Files to [your project's name]`
2. Go to `node_modules` ➜ `typingdnarecorder-react-native` and add `RNTypingdnarecorder.xcodeproj`
3. In XCode, in the project navigator, select your project. Add `libRNTypingdnarecorder.a` to your project's `Build Phases` ➜ `Link Binary With Libraries`
4. In order for the Xcode project to build when you use Swift in the iOS static libary you include in the module, your main app project must contain Swift code and a bridging header itself. If your app does not contain Swift code, you can add an empty Swift source file with a bridging header to the project.
5. Run your project (`Cmd+R`)

#### Android

1. Open up `android/app/src/main/java/[...]/MainApplication.java`
  - Add `import com.typingdna.RNTypingdnarecorderPackage;` to the imports at the top of the file
  - Add `new RNTypingdnarecorderPackage()` to the list returned by the `getPackages()` method
2. Append the following lines to `android/settings.gradle`:
  	```
  	include ':typingdnarecorder-react-native'
  	project(':typingdnarecorder-react-native').projectDir = new File(rootProject.projectDir, 	'../node_modules/typingdnarecorder-react-native/android')
  	```
3. Insert the following lines inside the dependencies block in `android/app/build.gradle`:
  	```
      implementation project(':typingdnarecorder-react-native')
  	```
4. Edit the following lines in `build.gradle`:
		```
			buildToolsVersion = "28.0.3"
			minSdkVersion = 19
			compileSdkVersion = 28
			targetSdkVersion = 28
			supportLibVersion = "28.0.0"
		```
5. Add the following lines to `AndroidManifest.xml` before `<application>`:
		```
			<uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW"/>
    	<uses-permission android:name="android.permission.TYPE_APPLICATION_OVERLAY"/>
		```

## Usage

##### Import the library:
```javascript
import tdna from 'typingdnarecorder-react-native';
```

##### Methods:
- ```initialize()```: must be called before using the library.
- ```start()```: starts the recorder.
- ```stop()```: stops the recorder.
- ```reset()```: resets the recorder. All targets will be kept, but the recorded data will be discarded.
- ```addTarget(target)```: add a new target for the recorder to monitor. For android should be the id of the input field (ref._inputRef._nativeTag) and on iOS the placeholder (ref.props.placeholder).
- ```removeTarget(target)```: remove a target.
- ```getTypingPattern(type, length, text, textId, targetId, caseSensitive, callback)```: get the typing pattern for the specified input field and invoke the callback with it.

Where:

* **type** the type of the pattern
	* **0** - used when comparing random text of usually 120-180 characters long
	* **1** - recommended for email passwords, phone numbers, credit card numbers, short texts
	* **2** - best accuracy, recommended when the text is not a secret

* **length** (NOT required for type 0) length of the text for which you want the typing pattern

* **text** (NOT required for type 0) a typed string that you want the typing pattern for

* **textId** (Optional - 0 = ignore) a personalized id for the type text

* **targetId** specifies from which target the pattern should be recorded from

* **caseSensitive** (NOT required for type 0) Used only if you pass a text for type 1
  
  
```javascript
import React, {Component} from 'react';
import {StyleSheet, Text, View, TextInput, Button, Platform} from 'react-native';
import tdna from 'typingdnarecorder-react-native';

type Props = {};
export default class App extends Component<Props> {

  constructor(props) {
    super(props);

    this.state = {
      pattern: "",
      text: ""
    };
  }

  componentDidMount() {
    setTimeout(() => {
      tdna.initialize();
      tdna.start();
      tdna.addTarget(this.targetId);
    }, 1000);
  }
                                                     
  componentWillUnmount() {
    tdna.stop();
  }

  reset() {
    tdna.reset();
    this.setState({pattern: "", text: ""});
  }

  getTypingPattern() {
    tdna.getTypingPattern(0, 0, "", 0, this.targetId, false, (tp) => {
      this.setState({pattern: tp});
    });
  }

  render() {
    return (
      <View style={styles.container}>
        <Text style={styles.welcome}>Pattern</Text>
        <Text style={styles.instructions}>{this.state.pattern}</Text>
        
        <TextInput
          ref={ref => { if (!this.targetId && ref && ref._inputRef && ref._inputRef._nativeTag) {
            if (Platform.OS === 'ios') {
              this.targetId = ref.props.placeholder;
            }
            else {
              this.targetId = ref._inputRef._nativeTag;
            }
          }}}
          placeholder={"Enter text"} 
          onChangeText={(text) => this.setState({text})}
          value={this.state.text}
          />

        <View style={{flex: 1, flexDirection: "row", justifyContent: "space-around", alignItems: "flex-start"}}>
        <Button
          title={"Get"}
          onPress={() => this.getTypingPattern()} />
        <Button
          title={"Reset"}
          onPress={() => this.reset()} />
        </View>
      </View>
    );
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#F5FCFF',
  },
  welcome: {
    fontSize: 20,
    textAlign: 'center',
    margin: 10,
  },
  instructions: {
    textAlign: 'center',
    color: '#333333',
    marginBottom: 5,
  },
});
```
  