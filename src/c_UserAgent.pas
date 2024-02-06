unit c_UserAgent;

interface

const
  // https://www.whatismybrowser.com/guides/the-latest-user-agent/chrome
  cBrowserUserAgent =
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) ' +
    'AppleWebKit/537.36 (KHTML, like Gecko) ' +
    'Chrome/121.0.0.0' + ' ' +
    'Safari/537.36';

  cGoogleEarthClientVersion = '7.3.6.9750';

  cGoogleEarthClientUserAgent =
    'GoogleEarth/' + cGoogleEarthClientVersion +
    '(Windows;Microsoft Windows (6.2.9200.0);en;kml:2.2;client:Pro;type:default)';

implementation

end.
