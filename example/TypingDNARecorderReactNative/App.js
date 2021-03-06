/**
 * @format
 * @flow strict-local
 */

import React from 'react';
import {
  StyleSheet,
  View,
  Text,
  TextInput,
  Button,
  Platform,
} from 'react-native';

import tdna from 'typingdnarecorder-react-native';

type Props = {};
export default class App extends React.Component<Props> {
  constructor(props) {
    super(props);

    this.state = {
      pattern: '',
      text: '',
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
    this.setState({pattern: '', text: ''});
  }

  getTypingPattern() {
    tdna.getTypingPattern(2, 0, '', 0, this.targetId, false, (tp) => {
      this.setState({pattern: tp});
    });
  }

  render() {
    return (
      <View style={styles.container}>
        <Text style={styles.welcome}>Pattern</Text>
        <Text style={styles.instructions}>{this.state.pattern}</Text>

        <TextInput
          multiline={true}
          numberOfLines={5}
          ref={(ref) => {
            if (!this.targetId && ref) {
              if (Platform.OS === 'ios') {
                // TextInput placeholder
                this.targetId = 'Enter text';
              } else {
                this.targetId = ref._nativeTag;
              }
            }
          }}
          placeholder={'Enter text'}
          onChangeText={(text) => this.setState({text})}
          value={this.state.text}
        />

        <View
          style={{
            flex: 1,
            flexDirection: 'row',
            justifyContent: 'space-around',
            alignItems: 'flex-start',
          }}>
          <Button title={'Get'} onPress={() => this.getTypingPattern()} />
          <Button title={'Reset'} onPress={() => this.reset()} />
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
