import 'package:flutter/material.dart';

class SettingPage extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingPage> {
  bool _switchVal = true;
  double _sliderVal = 0.5;
  String _selectedOption = 'One';
  int _numberInput = 0;
  String _textInput = '';

  // 模拟的参数设置持久化函数
  void onSettingChanged(String settingName, dynamic value) {
    // 在这里持久化设置
    print('Setting changed: $settingName = $value');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildCategory("Network"),
            _buildSwitchListTile('Wi-Fi', 'Enable Wi-Fi', _switchVal,
                (bool value) {
              setState(() {
                _switchVal = value;
                onSettingChanged('Wi-Fi', value);
              });
            }),
            _buildSliderListTile(
                'Download Limit',
                'Set the maximum download bandwidth',
                _sliderVal, (double value) {
              setState(() {
                _sliderVal = value;
                onSettingChanged('Download Limit', value);
              });
            }),
            _buildCategory("Account"),
            _buildDropdownListTile(
                'User Role', 'Select your role', 'One', ['One', 'Two', 'Three'],
                (String newValue) {
              setState(() {
                _selectedOption = newValue;
                onSettingChanged('User Role', newValue);
              });
            }),
            _buildTextFormField('Username', 'Enter your username', _textInput,
                (String value) {
              setState(() {
                _textInput = value;
                onSettingChanged('Username', value);
              });
            }),
            _buildNumberField('Age', 'Enter your age', _numberInput,
                (String value) {
              setState(() {
                _numberInput = int.parse(value);
                onSettingChanged('Age', _numberInput);
              });
            }),
            _buildConfigurationButton('Advanced Settings', () {
              // 弹出对话框，进行高级配置
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text('Advanced Settings'),
                  content: Text('Configure advanced settings here.'),
                  // Replace this Text widget with the widgets for parameter configuration.
                ),
              );
            }),
            // 添加更多设置项...
          ],
        ),
      ),
    );
  }

  Widget _buildCategory(String title) {
    return Container(
      alignment: Alignment.centerLeft, // 设置容器内的子元素靠左对齐
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 22.0,
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey[700], // 深灰色作为分类标题颜色
        ),
      ),
    );
  }

  // 调整后的设置项标题样式
  Widget _buildTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16.0, // 中等大小字号
        fontWeight: FontWeight.w500, // 适中加粗
        color: Colors.black87, // 略深的文字颜色
      ),
    );
  }

  Widget _buildSubtitle(String subtitle) {
    return Text(
      subtitle,
      style: TextStyle(
        fontSize: 14.0, // 较小字号
        color: Colors.black54, // 灰色系文字颜色
      ),
    );
  }

  // 构建开关按钮设置项
  Widget _buildSwitchListTile(
      String title, String subtitle, bool value, Function onChanged) {
    return SwitchListTile(
      title: _buildTitle(title),
      subtitle: _buildSubtitle(subtitle),
      value: value,
      onChanged: (bool newValue) => onChanged(newValue),
    );
  }

  // 构建滑块设置项
  Widget _buildSliderListTile(
      String title, String subtitle, double value, Function onChanged) {
    return ListTile(
      title: _buildTitle(title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSubtitle(subtitle),
          Slider(
            min: 0.0,
            max: 1.0,
            divisions: 100,
            label: '${(value * 100).toInt()}%',
            value: value,
            onChanged: (double newValue) => onChanged(newValue),
          ),
        ],
      ),
    );
  }

  // 构建下拉菜单设置项
  Widget _buildDropdownListTile(String title, String subtitle,
      String selectedValue, List<String> options, Function onChanged) {
    return ListTile(
      title: _buildTitle(title),
      trailing: DropdownButton<String>(
        value: selectedValue,
        items: options.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: (String? value) {
          print("你选中的文字:${value}");
        },
      ),
      subtitle: _buildSubtitle(subtitle),
    );
  }

  // 构建文本输入设置项
  // 调整后的 ListTile 包含 TextFormField
  Widget _buildTextFormField(
      String title, String subtitle, String initialValue, Function onSaved) {
    return ListTile(
      title: _buildTitle(title),
      subtitle: TextFormField(
        initialValue: initialValue,
        decoration: InputDecoration(
          hintText: subtitle,
          hintStyle: TextStyle(color: Colors.black54), // 灰色系文字颜色
        ),
        onFieldSubmitted: (String value) => onSaved(value),
      ),
    );
  }

  // 构建数字输入设置项
  Widget _buildNumberField(
      String title, String subtitle, int initialValue, Function onSaved) {
    return ListTile(
      title: Text(title),
      subtitle: TextFormField(
        initialValue: initialValue.toString(),
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          hintText: subtitle,
        ),
        onFieldSubmitted: (String value) => onSaved(value),
      ),
    );
  }

  // 构建配置按钮
  Widget _buildConfigurationButton(String title, Function onTap) {
    return ListTile(
      title: Text(title),
      trailing: IconButton(
        icon: Icon(Icons.settings),
        onPressed: () => onTap(),
      ),
    );
  }

// 添加更多构建函数...
}
