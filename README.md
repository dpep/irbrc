Irbrc
======
Accelerate development speed with per project irbrc files.  This utility makes it easy to load helper functions or code under development into irb sessions.


#### Install
```bash
gem install irbrc
```


#### Usage
Create .irbrc file manually, or automatically via
```ruby
require 'irbrc'
Irbrc::init
```

Then call:
```ruby
load_rc
```
