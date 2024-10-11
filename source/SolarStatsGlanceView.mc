//
// Copyright 2022-2024 by garmin@emeska.nl
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and 
// associated documentation files (the "Software"), to deal in the Software without restriction, 
// including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, 
// and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, 
// subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or 
// substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING 
// BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND 
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, 
// DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Application.Storage;

(:glance) 
class SolarStatsGlanceView extends WatchUi.GlanceView
{
    function initialize() {
        GlanceView.initialize();
    }
    
    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_BLACK,Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(Graphics.COLOR_WHITE,Graphics.COLOR_TRANSPARENT);

        var status = Application.getApp().status;
        var text2display = (status.generated/1000).toFloat().format("%.1f") + " kWh @ " + status.time;
        if ( status.period == unknown) {
            text2display = Application.loadResource($.Rez.Strings.AppName) as String;
        }
        
        dc.drawText(0, 
                    dc.getHeight()/2, 
                    Graphics.FONT_TINY,
                    text2display, 
                    Graphics.TEXT_JUSTIFY_LEFT|Graphics.TEXT_JUSTIFY_VCENTER);
    } 

    function onStop() {
    }
}
