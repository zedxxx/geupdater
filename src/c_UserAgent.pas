unit c_UserAgent;

interface

const
  cGoogleChromeVersion = '146.0.0.0';
  cGoogleEarthClientVersion = '7.3.7.1094';

  // https://www.whatismybrowser.com/guides/the-latest-user-agent/chrome
  cGoogleChromeUserAgent =
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) ' +
    'Chrome/' + cGoogleChromeVersion + ' Safari/537.36';

  cGoogleEarthClientUserAgent =
    'GoogleEarth/' + cGoogleEarthClientVersion +
    '(Windows;Microsoft Windows (6.2.9200.0);en;kml:2.2;client:Pro;type:default)';

implementation

end.
