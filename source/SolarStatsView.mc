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

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Application;
import Toybox.Application.Storage;
import Toybox.Application.Properties;
import Toybox.Math;
import Toybox.Time.Gregorian;

enum GraphTypes {
    lineGraph,
    barGraph
}

//! Shows the Solar panel results
class SolarStatsView extends WatchUi.View {
    private var _stats = new SolarStats();
    private var _graph = [] as Array;
    private var _settings = new SolarSettings([]);
    private var _error as Boolean = false;
    private var _message = _na_ as String;
    private var _today = _na_ as String;
    private var _day = _na_ as String;
    private var _week = _na_ as String;
    private var _last6hours = _na_ as String;
    private var _total = _na_ as String;
    private var _consumed = _na_ as String;
    private var _current = _na_ as String;
    private var _invalid = _na_ as String;
    private var _errorMessage = null as WatchUi.TextArea;
    protected var _showconsumption = false as Boolean;
    protected var _showextended = false as Boolean;
    protected var _extvalue = 0 as Long;

    //! Constructor
    hidden function initialize() {
        WatchUi.View.initialize();
        
        _showconsumption = Properties.getValue($.consumption);
    }

    //! Load your resources here
    //! @param dc Device context
    public function onLayout(dc as Dc) as Void {
        _today      = WatchUi.loadResource($.Rez.Strings.today) as String;
        _day        = WatchUi.loadResource($.Rez.Strings.day) as String;
        _week       = WatchUi.loadResource($.Rez.Strings.week) as String;
        _total      = WatchUi.loadResource($.Rez.Strings.total) as String;
        _consumed   = WatchUi.loadResource($.Rez.Strings.consumed) as String;
        _current    = WatchUi.loadResource($.Rez.Strings.current) as String;
        _last6hours = WatchUi.loadResource($.Rez.Strings.last6hours) as String;
        _invalid    = WatchUi.loadResource($.Rez.Strings.invalid) as String;
    }

    //! Restore the state of the app and prepare the view to be shown
    public function onShow() as Void {
        var stored = Storage.getValue("status");
        if ( stored != null ) {
            _stats.set(stored);
        }
    }

    //! Update the view
    //! @param dc Device Context
    public function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        try {
            if ( !_error ) {
                if ( _graph.size() == 0 ) {
                    ShowOverview(dc);
                } 
                else {
                    switch ( GraphType(_graph[0].period) ) {
                    case lineGraph:
                        ShowLineGraph(dc, _graph);
                        break;
                    case barGraph:
                        ShowBarGraph(dc, _graph);
                        break;
                    default:
                        break;
                    }
                }
            } else {
                ShowError(dc);
            }
        }
        catch ( ex instanceof Lang.Exception ) {
            ex.printStackTrace();

            // display an error message, not really helpful, but at least no crash
            _message = ex.getErrorMessage();
            ShowError(dc);
        }
    }

    protected function ShowOverview( dc as Dc) as Void {
        throw new Lang.Exception();
    }

    protected function ShowGeneration(dc as Dc) {

        var fhXLarge = dc.getFontHeight(Graphics.FONT_SYSTEM_NUMBER_THAI_HOT);
        var fhLarge  = dc.getFontHeight(Graphics.FONT_SYSTEM_LARGE);
        
        var locHeader = 0.05*dc.getHeight();
        var locTime = 0.82*dc.getHeight();
        
        var generated = (_stats.generated/1000).format("%.1f");
        var dimGen = dc.getTextDimensions(generated, Graphics.FONT_SYSTEM_NUMBER_THAI_HOT);

        var genX = dc.getWidth() / 2;
        var genY = dc.getHeight() / 2 - dc.getHeight()*0.03;
        var kWhX = genX + dimGen[0]/2 + 2;
        var prodY = genY + fhXLarge/2;

        dc.drawText(dc.getWidth() / 2, locHeader, 
                                Graphics.FONT_SYSTEM_LARGE, 
                                Header(_stats), 
                                Graphics.TEXT_JUSTIFY_CENTER );

        dc.drawText(genX, genY, Graphics.FONT_SYSTEM_NUMBER_THAI_HOT, 
                                generated, 
                                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER );
                                
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_BLACK);
        dc.drawText(kWhX, genY, Graphics.FONT_SYSTEM_XTINY, 
                                "kWh", 
                                Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER );

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.drawText(dc.getWidth() / 2, prodY, 
                                Graphics.FONT_SYSTEM_XTINY, 
                                _current + ": " + _stats.generating.format("%.0f") + " W", 
                                Graphics.TEXT_JUSTIFY_CENTER );

        dc.drawText(dc.getWidth() / 2, locTime, 
                                Graphics.FONT_SYSTEM_XTINY, 
                                "@" + _stats.time.substring(0,5), 
                                Graphics.TEXT_JUSTIFY_CENTER );
    }

    protected function ShowValues(dc as Dc) {
        var fhLarge = dc.getFontHeight(Graphics.FONT_SYSTEM_LARGE);
        var fhXTiny = dc.getFontHeight(Graphics.FONT_SYSTEM_XTINY);
        var fhTiny  = dc.getFontHeight(Graphics.FONT_SYSTEM_TINY);
        
        var locHeader = dc.getHeight() / 2 - 2*fhLarge - fhTiny;
        var locGenerated = locHeader;
        var locGeneration = locHeader;
        var locConsumed = dc.getHeight() / 2 + 6;
        var locConsumption = locConsumed + fhTiny;
        var locExtended = locConsumption + fhXTiny + 2;
        var locTime = dc.getHeight() / 2 + 2*fhLarge;

        locGenerated = locGenerated + fhLarge + 5;
        locGeneration = locGenerated + fhLarge;

        dc.drawText(dc.getWidth() / 2, locHeader, Graphics.FONT_LARGE, Header(_stats), Graphics.TEXT_JUSTIFY_CENTER );
        
        dc.drawText(dc.getWidth() / 2, locGenerated, Graphics.FONT_SYSTEM_LARGE, (_stats.generated/1000).format("%.1f") + " kWh", Graphics.TEXT_JUSTIFY_CENTER );
        dc.drawText(dc.getWidth() / 2, locGeneration, Graphics.FONT_SYSTEM_XTINY, _current + ": " + _stats.generating.format("%.0f") + " W", Graphics.TEXT_JUSTIFY_CENTER );
        dc.drawText(dc.getWidth() / 2, locTime, Graphics.FONT_SYSTEM_XTINY, "@ " + _stats.time.substring(0,5), Graphics.TEXT_JUSTIFY_CENTER );

        dc.drawText(dc.getWidth() / 2, locConsumed, Graphics.FONT_SYSTEM_TINY, _consumed + ": " + (_stats.consumed/1000).format("%.1f")+ " kWh", Graphics.TEXT_JUSTIFY_CENTER );
        dc.drawText(dc.getWidth() / 2, locConsumption, Graphics.FONT_SYSTEM_XTINY, _current + ": " + _stats.consuming.format("%.1f") + " W", Graphics.TEXT_JUSTIFY_CENTER );
        if ( _showextended ) {
            dc.drawText(dc.getWidth() / 2, locExtended, Graphics.FONT_SYSTEM_XTINY, _settings.getLabel(_extvalue) + 
                        ": " + _stats.extended[_extvalue].format("%.1f") + " " + _settings.getUnit(_extvalue), 
                        Graphics.TEXT_JUSTIFY_CENTER );
        }
    }

    private function ShowLineGraph(dc as Dc, values as Array<SolarStats>) {
        // Find the max power/index in the array
        var maxIndex  = MaxGeneration(values);
        var maxPower = values[maxIndex].generating;
        if ( maxPower == null ) {
            maxPower = 0;
        }

        var width = dc.getWidth() as Long;
        var wideX = 0.80*width as Float;
        var wideY = 0.45*width as Float;
        var stepSize = (Math.round(wideX/values.size())).toLong();
        var offsetX = ((width / 2) + (stepSize*values.size()/2)).toLong();
        var offsetY = ((width / 2) + (wideY/2)).toLong();
        var height = wideY;

        // normalize power on y-axis
        var norm = Normalize(maxPower, height);

        if (dc has :setAntiAlias) {
            dc.setAntiAlias(true);
        }
        dc.setPenWidth(2);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_BLACK);
        dc.drawLine (0, offsetY, width, offsetY);                       // x-axis
        dc.drawLine (offsetX, offsetY + 5, offsetX, offsetY - height);  // y-axis

        // draw 500W lines
        var yIdx = maxPower / 500;
        for ( var i = 1; i <= yIdx; i ++ ) {
            dc.drawLine( offsetX - 3, (offsetY - i*500/norm).toLong(), offsetX + 3, (offsetY - i*500/norm).toLong());
        }

        var fX = offsetX;
        var fY = offsetY - (values[0].generating / norm).toLong();
        for ( var i = 1; i < values.size(); i++ ) {
            var tX = offsetX - stepSize*i;
            var tY = offsetY - (values[i].generating / norm).toLong();
            
            dc.setPenWidth(2);
            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_BLACK);
            dc.drawLine(fX, fY, tX, tY);

            if ( i == maxIndex ) {
                dc.setPenWidth(1);
                dc.setColor(Graphics.COLOR_DK_GREEN, Graphics.COLOR_BLACK);
                dc.drawLine(offsetX - stepSize*i, offsetY, offsetX - stepSize*i, offsetY - height);
            }

            if ( values[i].time.find(":00") == 2 ) {
                dc.setPenWidth(1);
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
                dc.drawLine(offsetX - stepSize*i, offsetY + 5, offsetX - stepSize*i, offsetY - 5);

                var hour = values[i].time.substring(0,2).toLong();
                if ( hour % 3 == 0 ) {
                    dc.drawText(offsetX - stepSize*i, offsetY + 3, Graphics.FONT_SYSTEM_XTINY, hour.toString(), Graphics.TEXT_JUSTIFY_CENTER );
                }
            }

            fX = tX;
            fY = tY;
        }

        var fhTiny  = dc.getFontHeight(Graphics.FONT_SYSTEM_TINY);
        var fhXTiny = dc.getFontHeight(Graphics.FONT_SYSTEM_XTINY);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.drawText(dc.getWidth() / 2, (dc.getHeight() + height) / 2 + fhTiny, Graphics.FONT_SYSTEM_TINY, Header(values[0]), Graphics.TEXT_JUSTIFY_CENTER);
        if ( values[0].generating != null ) {
            dc.drawText(dc.getWidth() / 2, (dc.getHeight() - height) / 2 - fhTiny - fhXTiny - 5, Graphics.FONT_SYSTEM_TINY, (values[0].generating).format("%.1f") + " W", Graphics.TEXT_JUSTIFY_CENTER );
        } else {
            dc.drawText(dc.getWidth() / 2, (dc.getHeight() - height) / 2 - fhTiny - fhXTiny - 5, Graphics.FONT_SYSTEM_TINY, "Off", Graphics.TEXT_JUSTIFY_CENTER );
        }
        dc.drawText(dc.getWidth() / 2, (dc.getHeight() - height) / 2 - fhXTiny - 5, Graphics.FONT_SYSTEM_XTINY, "Max: " + (values[maxIndex].generating).format("%.0f") + " W @ " + values[maxIndex].time.substring(0,5), Graphics.TEXT_JUSTIFY_CENTER );
    }

    private function ShowBarGraph(dc as Dc, values as Array<SolarStats>) {
        // First find the max index/value in the array
        var mig  = MaxGenerated(values);
        var mg = values[mig].generated;
        var mic = MaxConsumption(values);
        var mc = values[mic].consumed;

        var maxIndex = mig;
        var maxPower = mg;
        if ( _showconsumption and mc > mg ) {
            maxIndex = mic;
            maxPower = mc;
        }

        var width = dc.getWidth() as Long;
        var wideX = 0.80*width as Float;
        var wideY = 0.45*width as Float;
        var stepSize = (Math.round(wideX/values.size())).toLong();
        var offsetX = ((width / 2) + (stepSize*values.size()/2)).toLong();
        var offsetY = ((width / 2) + (wideY/2)).toLong();
        var height = wideY;

        // normalize power on y-axis
        var norm = Normalize(maxPower, height);

        // draw axis
        if (dc has :setAntiAlias) {
            dc.setAntiAlias(true);
        }
        dc.setPenWidth(2);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_BLACK);
        dc.drawLine (0, offsetY, width, offsetY);                       // x-axis
        dc.drawLine (offsetX, offsetY + 5, offsetX, offsetY - height);  // y-axis

        var divider = 100000;               // draw 100kWh lines
        if ( maxPower < 50000 ) {
            divider = 5000;                 // draw 5kWh lines
        } else if ( maxPower > 1000000 ) {  
            divider = 500000;               // draw 500kWh lines
        }
        var yIdx = maxPower / divider;

        //draw vertical ticks
        for ( var i = 1; i <= yIdx; i ++ ) {
            dc.drawLine( offsetX - 3, (offsetY - i*divider/norm).toLong(), offsetX + 3, (offsetY - i*divider/norm).toLong());
        }

        var fhTiny  = dc.getFontHeight(Graphics.FONT_SYSTEM_TINY);
        var fhXTiny = dc.getFontHeight(Graphics.FONT_SYSTEM_XTINY);

        var cumGen = 0;
        var cumCon = 0;

        for ( var i = 0; i < values.size(); i++ ) {
            cumGen += values[i].generated;
            cumCon += values[i].consumed;

            //show generation
            var x1 = offsetX - stepSize*(i+1) + Offset(stepSize) + 1;
            var w1 = stepSize - 1 - 2*Offset(stepSize);
            var h1 = (values[i].generated / norm).toLong();
            var y1 = offsetY - h1;
            drawGenerationRectangle(dc, x1, y1, w1, h1);

            //show consumption
            var x2 = x1 - OffsetConsumption(stepSize);
            var w2 = w1 + 2*OffsetConsumption(stepSize) + (IsNarrow(stepSize) ? 0 : 1);
            var h2 = (values[i].consumed / norm).toLong();
            var y2 = offsetY - h2;
            var penWidth = IsNarrow(stepSize) ? 1 : 2;
            if ( _showconsumption ) {
                drawConsumptionRectangle(dc, x2, y2, w2, h2, penWidth);
            }

            // Draw tickline
            dc.setPenWidth(1);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
            dc.drawLine(offsetX - stepSize*i, offsetY + 5, offsetX - stepSize*i, offsetY - 5);

            // Show date label
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);

            var dateString = Date(values[i]);
            var textWidth = dc.getTextWidthInPixels(dateString, Graphics.FONT_SYSTEM_XTINY);
            
            if ( (textWidth+1) > stepSize and dateString.length() == 3 ) {
                // reduce width for year overview
                dateString = dateString.substring(0, 1);
                textWidth = dc.getTextWidthInPixels(dateString, Graphics.FONT_SYSTEM_XTINY);
            }
            
            if ( values[i].period == monthStats && dateString.length() == 1 ) {
                // make sure the month view uses regular spacing - two characters but necessarily not display
                textWidth = textWidth + dc.getTextWidthInPixels("0", Graphics.FONT_SYSTEM_XTINY);
            }
            
            if ( ShowLabel(i, textWidth, stepSize) ) {
                dc.drawText(offsetX - stepSize*(i+0.5), offsetY+1, Graphics.FONT_SYSTEM_XTINY, dateString, Graphics.TEXT_JUSTIFY_CENTER );
            }
        }


        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.drawText(dc.getWidth() / 2, (dc.getHeight() + height) / 2 + fhXTiny, Graphics.FONT_SYSTEM_TINY, Header(values[0]), Graphics.TEXT_JUSTIFY_CENTER);
        if ( cumGen < 10000000 ) {
            dc.drawText(dc.getWidth() / 2, (dc.getHeight() - height) / 2 - fhTiny - fhXTiny - 5, Graphics.FONT_SYSTEM_TINY, ((cumGen/1000).toFloat()).format("%.0f") + " kWh", Graphics.TEXT_JUSTIFY_CENTER );
        } else {
            dc.drawText(dc.getWidth() / 2, (dc.getHeight() - height) / 2 - fhTiny - fhXTiny - 5, Graphics.FONT_SYSTEM_TINY, ((cumGen/1000000).toFloat()).format("%.2f") + " MWh", Graphics.TEXT_JUSTIFY_CENTER );
        }
        if ( _showconsumption ) {
            if ( cumCon < 10000000 ) {
                dc.drawText(dc.getWidth() / 2, (dc.getHeight() - height) / 2 - fhXTiny - 5, Graphics.FONT_SYSTEM_XTINY, _consumed + ": " + ((cumCon/1000).toFloat()).format("%.0f") + " kWh", Graphics.TEXT_JUSTIFY_CENTER );
            } else {
                dc.drawText(dc.getWidth() / 2, (dc.getHeight() - height) / 2 - fhXTiny - 5, Graphics.FONT_SYSTEM_XTINY, _consumed + ": " + ((cumCon/1000000).toFloat()).format("%.2f") + " MWh", Graphics.TEXT_JUSTIFY_CENTER );
            }

            
        }
    }

    private function GraphType( period as String ) as GraphTypes {
        return (period == currentStats) ? lineGraph : barGraph;
    }

    private function IsNarrow( stepSize as Long ) as Boolean {
        return (stepSize < 20);
    }

    private function Offset( stepSize as Long ) as Number {
        return IsNarrow(stepSize) | !_showconsumption ? 1 : 4;
        }

    private function OffsetConsumption( stepSize as Long ) as Number {
        return IsNarrow(stepSize) ? 1 : 2;
        }

    // Function to draw a rectangle for generation
    private function drawGenerationRectangle( dc as Dc, x as Long, y as Long, width as Long, height as Long ) {
            dc.setPenWidth(1);
            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_BLACK);
            dc.fillRectangle(x, y, width, height);
        }

    // Function to draw a rectangle based on conditions
    private function drawConsumptionRectangle( dc as Dc, x as Long, y as Long, width as Long, height as Long, penWidth as Number ) {
        dc.setPenWidth(penWidth);
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_BLACK);
        dc.drawRectangle(x, y, width, height);
    }

    private function ShowLabel( index as Number, textWidth as Number, labelWidth as Long ) as Boolean {
        var divider = textWidth / labelWidth + 1;
        return (index % divider == 0) ? true : false;
    }

    private function Normalize( maximum as Long, height as Float ) as Float {
        PreconditionCheck( height > 0 );
        var norm = maximum / height;
        return (norm < 1.0) ? 1.0 : norm;
    }

    private function PreconditionCheck( valid as Boolean ) {
        if ( !valid ) {
            throw new Lang.InvalidValueException(_invalid);
        }
    }

    private function Date( stats as SolarStats ) as String {
        var dI = DateStringToInfo(stats.date);

        var dateString = stats.date;
        switch ( stats.period ) {
            case weekStats:
                dateString = dI.day_of_week.substring(0,1);
                break;
            case monthStats:
                dateString = dI.day.toString();
                break;
            case yearStats:
                dateString = dI.month;
                break;
            case totalStats:
                dateString = dI.year.toString();
                break;
            default:
                break;
        }
        return dateString;
    }

    private function MaxGenerated( array as Array<SolarStats> ) as Number {
        var maxIndex = 0;
        var maxPower = 0;
        for ( var i = 0; i < array.size(); i++ ) {
            if ( array[i].generated > maxPower ) {
                maxPower = array[i].generated;
                maxIndex = i;
            }
        }
        return maxIndex;
    }

    private function MaxGeneration( array as Array<SolarStats> ) as Number {
        var maxIndex = 0;
        var maxPower = 0;
        for ( var i = 0; i < array.size(); i++ ) {
            if ( array[i].generating > maxPower ) {
                maxPower = array[i].generating;
                maxIndex = i;
            }
        }
        return maxIndex;
    }

    private function MaxConsumption( array as Array<SolarStats> ) as Number {
        var maxIndex = 0;
        var maxPower = 0;
        for ( var i = 0; i < array.size(); i++ ) {
            if ( array[i].consumed > maxPower ) {
                maxPower = array[i].consumed;
                maxIndex = i;
            }
        }
        return maxIndex;
    }

    private function ShowError(dc as Dc) {
        _errorMessage = new WatchUi.TextArea({
            :text=>_message,
            :font=>[Graphics.FONT_MEDIUM, Graphics.FONT_SMALL, Graphics.FONT_XTINY],
            :locX =>WatchUi.LAYOUT_HALIGN_CENTER,
            :locY=>WatchUi.LAYOUT_VALIGN_CENTER,
            :justification=>Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER,
            :width=>dc.getHeight()*0.66,
            :height=>dc.getWidth()*0.66
        });        
        _errorMessage.draw(dc);
    }

    private function Header( stats as SolarStats ) as String {
        var header = _na_;
        switch ( stats.period ) {
            case dayStats:
                header = _today;
                break;
            case currentStats:
                header = _last6hours;
                break;
            case weekStats:
                header = _week;
                break;
            case monthStats:
                header = Gregorian.info(Time.today(), Time.FORMAT_LONG).month;
                break;
            case yearStats:
                header = Gregorian.info(Time.today(), Time.FORMAT_SHORT).year;
                break;
            case totalStats:
                header = _total;
                break;
            default:
                break;
        }
        return header;
    }

    private function DateStringToInfo(dateString as String ) as Gregorian.Info {
        return DateInfo(dateString.substring(0,4), dateString.substring(5,7), dateString.substring(8,10));
    }

    private function DateInfo( year as String, month as String, day as String ) as Gregorian.Info {
        var options = {
            :year => year.toNumber(),
            :month => month.toNumber(),
            :day => day.toNumber(),
            :hour => 0,
            :minute => 0
        };
        return Gregorian.utcInfo(Gregorian.moment(options), Time.FORMAT_LONG);
    }

    //! Called when this View is removed from the screen. Save the
    //! state of your app here.
    public function onHide() as Void {
        Storage.setValue("status", _stats.toString());
    }

    //! Show the result or status of the web request
    //! @param args Data from the web request, or error message
    public function onReceive(result as SolarStats or SolarSettings or Array or String or Null) as Void {
        if (result instanceof String) {
            _error      = true;
            _message    = result;
            _graph      = [];
        } else if (result instanceof SolarStats ) {
            _error      = false;
            _stats      = result;
            _graph      = [];
        } else if (result instanceof Array ) {
            _error      = false;
            _graph      = result;
        } else if (result instanceof SolarSettings ) {
            _settings   = result;
        }
        WatchUi.requestUpdate();
    }
}
