//     Zepto.js
//     (c) 2010-2012 Thomas Fuchs
//     Zepto.js may be freely distributed under the MIT license.

;(function($){
  var touch = {},
    touchTimeout, tapTimeout, swipeTimeout,
    longTapDelay = 750, longTapTimeout

  function parentIfText(node) {
    return 'tagName' in node ? node : node.parentNode
  }

  function swipeDirection(x1, x2, y1, y2) {
    var xDelta = Math.abs(x1 - x2), yDelta = Math.abs(y1 - y2)
    return xDelta >= yDelta ? (x1 - x2 > 0 ? 'Left' : 'Right') : (y1 - y2 > 0 ? 'Up' : 'Down')
  }

  function longTap(e) {
    longTapTimeout = null
    if (touch.last) {
      // Set up correct pageX and pageY data for touch event
      var event = $.Event("longTap", {
        originalEvent: e,
        pageX: e.touches[0].clientX,
        pageY: e.touches[0].clientY
      })
      touch.el.trigger(event)
      touch = {}
    }
  }

  function cancelLongTap() {
    if (longTapTimeout) clearTimeout(longTapTimeout)
    longTapTimeout = null
  }

  function cancelAll() {
    if (touchTimeout) clearTimeout(touchTimeout)
    if (tapTimeout) clearTimeout(tapTimeout)
    if (swipeTimeout) clearTimeout(swipeTimeout)
    if (longTapTimeout) clearTimeout(longTapTimeout)
    touchTimeout = tapTimeout = swipeTimeout = longTapTimeout = null
    touch = {}
  }

  $(document).ready(function(){
    var now, delta

    $(document.body)
      .on('touchstart', function(e){
        var evt = e.originalEvent
        now = Date.now()
        delta = now - (touch.last || now)
        touch.el = $(parentIfText(evt.touches[0].target))
        touchTimeout && clearTimeout(touchTimeout)
        touch.x1 = evt.touches[0].pageX
        touch.y1 = evt.touches[0].pageY
        if (delta > 0 && delta <= 250) touch.isDoubleTap = true
        touch.last = now
        longTapTimeout = setTimeout(function() {longTap(evt)}, longTapDelay)
      })
      .on('touchmove', function(e){
        var evt = e.originalEvent
        cancelLongTap()
        touch.x2 = evt.touches[0].pageX
        touch.y2 = evt.touches[0].pageY
        if (Math.abs(touch.x1 - touch.x2) > 10)
          e.preventDefault()
      })
      .on('touchend', function(e){
          cancelLongTap()
          var evt = e.originalEvent

        // swipe
        if ((touch.x2 && Math.abs(touch.x1 - touch.x2) > 30) ||
            (touch.y2 && Math.abs(touch.y1 - touch.y2) > 30))

          swipeTimeout = setTimeout(function() {
            touch.el.trigger('swipe')
            touch.el.trigger('swipe' + (swipeDirection(touch.x1, touch.x2, touch.y1, touch.y2)))
            touch = {}
          }, 0)

        // normal tap
        else if ('last' in touch)

          // delay by one tick so we can cancel the 'tap' event if 'scroll' fires
          // ('tap' fires before 'scroll')
          tapTimeout = setTimeout(function() {

            // trigger universal 'tap' with the option to cancelTouch()
            // (cancelTouch cancels processing of single vs double taps for faster 'tap' response)
            var event = $.Event('tap')
            event.cancelTouch = cancelAll
            touch.el.trigger(event)

            // trigger double tap immediately
            if (touch.isDoubleTap) {
              touch.el.trigger('doubleTap')
              touch = {}
            }

            // trigger single tap after 250ms of inactivity
            else {
              touchTimeout = setTimeout(function(){
                touchTimeout = null
                touch.el.trigger('singleTap')
                touch = {}
              }, 250)
            }

          }, 0)

      })
      .on('touchcancel', cancelAll)

    $(window).on('scroll', cancelAll)
  })

  ;['swipe', 'swipeLeft', 'swipeRight', 'swipeUp', 'swipeDown', 'doubleTap', 'tap', 'singleTap', 'longTap'].forEach(function(m){
    $.fn[m] = function(callback){ return this.on(m, callback) }
  })
})(jQuery)
