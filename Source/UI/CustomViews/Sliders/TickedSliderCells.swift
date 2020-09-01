/*
    Customizes the look and feel of all ticked horizontal sliders
 */

import Cocoa

// Base class for all ticked horizontal slider cells
class TickedSliderCell: HorizontalSliderCell {
    
    var tickVerticalSpacing: CGFloat {return 1}
    var tickWidth: CGFloat {return 2}
    var tickColor: NSColor {return Colors.Effects.sliderTickColor}
    override var knobColor: NSColor {return Colors.Effects.sliderKnobColorForState(.active)}
    
    override var backgroundGradient: NSGradient {
        return Colors.Effects.sliderBackgroundGradient
    }
    
    override internal func drawBar(inside aRect: NSRect, flipped: Bool) {
        
        super.drawBar(inside: aRect, flipped: flipped)
        drawTicks(aRect)
    }
    
    internal func drawTicks(_ aRect: NSRect) {
        
        // Draw ticks (as notches, within the bar)
        let ticksCount = self.numberOfTickMarks
        
        if (ticksCount > 2) {
            
            for i in 1...ticksCount - 2 {
                drawTick(i, aRect)
            }
            
        } else if (ticksCount == 1) {
            drawTick(0, aRect)
        }
    }
    
    // Draws a single tick within a bar
    internal func drawTick(_ index: Int, _ barRect: NSRect) {
        
        let tickMinY = barRect.minY + tickVerticalSpacing
        let tickMaxY = barRect.maxY - tickVerticalSpacing
        
        let tickRect = rectOfTickMark(at: index)
        let x = (tickRect.minX + tickRect.maxX) / 2
        
        GraphicsUtils.drawLine(tickColor, pt1: NSMakePoint(x, tickMinY), pt2: NSMakePoint(x, tickMaxY), width: tickWidth)
    }
    
    override func drawTickMarks() {
        // Do nothing (ticks are drawn in drawBar)
    }
}

// Cell for pan slider
class PanTickedSliderCell: TickedSliderCell {
    
    override var barRadius: CGFloat {return 0}
    override var barInsetY: CGFloat {return 0.75}
    override var knobWidth: CGFloat {return 6}
    override var knobRadius: CGFloat {return 1}
    override var knobHeightOutsideBar: CGFloat {return 2}
    
    var backgroundColor: NSColor {ColorSchemes.systemScheme.effects.sliderBackgroundColor}
    var foregroundColor: NSColor {ColorSchemes.systemScheme.effects.activeUnitStateColor}
    
    // Draw entire bar with single gradient
    override internal func drawBar(inside aRect: NSRect, flipped: Bool) {
        
        let offsetRect = aRect.offsetBy(dx: 0, dy: 0.25)
        
        var drawPath = NSBezierPath.init(roundedRect: offsetRect, xRadius: barRadius, yRadius: barRadius)
        backgroundColor.setFill()
        drawPath.fill()
        
        drawTicks(aRect)
        
        // Draw rect between knob and center, to show panning
        let knobCenter = knobRect(flipped: false).centerX
        let barCenter = offsetRect.centerX
        let panRectX = min(knobCenter, barCenter)
        let panRectWidth = abs(knobCenter - barCenter)
        
        if panRectWidth > 0 {
            
            let panRect = NSRect(x: panRectX, y: offsetRect.minY, width: panRectWidth, height: offsetRect.height)
            drawPath = NSBezierPath.init(roundedRect: panRect, xRadius: barRadius, yRadius: barRadius)
            foregroundColor.setFill()
            drawPath.fill()
        }
    }
    
    override func knobRect(flipped: Bool) -> NSRect {
        
        let bar = barRect(flipped: flipped)
        let val = CGFloat(self.doubleValue)
        let perc: CGFloat = 50 + (val / 2)
        
        let startX = bar.minX + perc * bar.width / 100
        let xOffset = -(perc * knobWidth / 100)
        
        let newX = startX + xOffset
        let newY = bar.minY - knobHeightOutsideBar
        
        return NSRect(x: newX, y: newY, width: knobWidth, height: knobHeightOutsideBar * 2 + bar.height)
    }
}

// Cell for all ticked effects sliders
class EffectsTickedSliderCell: TickedSliderCell, EffectsUnitSliderCellProtocol {
    
    override var barRadius: CGFloat {return 1.5}
    override var barInsetY: CGFloat {return 0.5}
    
    override var knobWidth: CGFloat {return 10}
    override var knobRadius: CGFloat {return 1}
    override var knobHeightOutsideBar: CGFloat {return 2.5}
    
    override var knobColor: NSColor {
        return Colors.Effects.sliderKnobColorForState(self.unitState)
    }
    
    override var tickVerticalSpacing: CGFloat {return 1}
    
    override var foregroundGradient: NSGradient {
     
        switch self.unitState {
            
        case .active:   return Colors.Effects.activeSliderGradient
            
        case .bypassed: return Colors.Effects.bypassedSliderGradient
            
        case .suppressed:   return Colors.Effects.suppressedSliderGradient
            
        }
    }
    
    var unitState: EffectsUnitState = .bypassed
}

class EffectsTickedSliderPreviewCell: EffectsTickedSliderCell {
    
    override var knobColor: NSColor {
        
        switch self.unitState {
            
        case .active:   return Colors.Effects.defaultActiveUnitColor
            
        case .bypassed: return Colors.Effects.defaultBypassedUnitColor
            
        case .suppressed:   return Colors.Effects.defaultSuppressedUnitColor
            
        }
    }
    
    override var tickColor: NSColor {return Colors.Effects.defaultTickColor}
    
    override var backgroundGradient: NSGradient {
        return Colors.Effects.defaultSliderBackgroundGradient
    }
    
    override var foregroundGradient: NSGradient {
        
        switch self.unitState {
            
        case .active:   return Colors.Effects.defaultActiveSliderGradient
            
        case .bypassed: return Colors.Effects.defaultBypassedSliderGradient
            
        case .suppressed:   return Colors.Effects.defaultSuppressedSliderGradient
            
        }
    }
}
