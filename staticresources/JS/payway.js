// Copyright 2016 Qvalent Pty. Ltd.

"use strict";

var payway = (function() {
    var payWayRestApiOrigin = "https://api.payway.com.au";
    var correlationIdCounter = 0;
    var frameIdCounter = 0;

    function log( message ) {
        if ( window.console && window.console.log ) {
            window.console.log( 'payway: ' + message );
        }
    }

    function extend( a, b ) {
        for ( var key in b ) {
            if ( b.hasOwnProperty( key ) ) {
                a[key] = b[key];
            }
        }
        return a;
    }

    function onReady( scope, err ) {
        var frame = {};
        frame.getToken = function( callback ) {
            if ( typeof callback !== 'function' ) {
                log( 'You must provide a callback function as the first parameter to \'frame.getToken\'' );
                return;
            }

            sendMessageToFrame( 'getToken', scope, {
                correlationId: correlationIdCounter
            } );
            scope.tokenCallbacks[correlationIdCounter] = callback;
            ++correlationIdCounter;
        };
        frame.destroy = function() {
            if ( scope.formElement && 
                 scope.formElement.payWaySubmitCallback ) {
                removeEvent( scope.formElement, 'submit', scope.formElement.payWaySubmitCallback );
            }
            if ( scope.messageListener ) {
                removeEvent( window, 'message', scope.messageListener );
            }
            if ( scope.formElement ) {
                delete scope.formElement.paywayFrame;
            }

            frame.getToken = function() {
                log( 'You cannot get a token after the frame has been destroyed' );
            };
            frame.destroy = function() {};

            if ( scope.iframeElement && scope.iframeElement.parentNode ) {
                scope.iframeElement.parentNode.removeChild( scope.iframeElement );
                delete scope.iframeElement; 
            }
        };

        if ( !err && scope.tokenMode === 'post' ) {
            // Setup an onsubmit trigger for our form which will send a message to the iframe.
            var informIframeOnSubmit = function( event ) {
                frame.getToken( function( err, data ) {
                    if ( err ) {
                        log( 
                            'An error occurred sending ' + 
                            ( scope.paymentMethod === 'creditCard' ? 'credit card' : 'bank account' ) +
                            ' data to PayWay.' );
                        log( 'HTTP ' + err.status + ': ' + err.message );
                        return;
                    }
                    submitTokenToMerchant( data.singleUseTokenId, scope );
                });
                // Prevent the form from being submitted.
                event.preventDefault();
            };
            addEvent( scope.formElement, 'submit', informIframeOnSubmit, false );
            scope.formElement.payWaySubmitCallback = informIframeOnSubmit;
        }

        scope.createdCallback( err, frame );
    }

    function receiveMessage( event, scope ) {
        "use strict";

        // All messages must be received from our known origin.
        if ( event.origin !== payWayRestApiOrigin ) {
            log( 'Message received from unknown origin' + event.origin + '. Ignoring message' );
            return;
        }

        if ( !event.data ) {
            log( 'event.data is empty or undefined' );
            return;
        }

        var data;
        try {
            data = JSON.parse( event.data );
        }
        catch ( ex ) {
            log( 'event.data was not valid JSON' );
            return;
        }

        if ( !data || !data.app || data.app !== 'payway' || data.frameId !== scope.frameId ) {
            // Message was not intended for us.
            return;
        }

        if ( data.type === 'ready' ) {
            onReady( scope, data.err );
        } else if ( data.type === 'valid' ) {
            scope.onValid();
        } else if ( data.type === 'invalid' ) {
            scope.onInvalid();
        } else if ( data.type === 'singleUseToken' ) {
            if ( !data.hasOwnProperty( 'correlationId' ) ||
                 typeof data.correlationId !== 'number' ) {
                var error = 'correlationId was not found on message or was not a number';
                log( error );
                return;
            }

            scope.tokenCallbacks[data.correlationId]( data.err, {
                singleUseTokenId: data.singleUseTokenId,
                paymentMethod: data.paymentMethod,
                creditCard: data.creditCard,
                bankAccount: data.bankAccount
            });
            delete scope.tokenCallbacks[data.correlationId];
        }
    }

    function submitTokenToMerchant( singleUseTokenId, scope ) {
        var hiddenField = document.createElement( 'input' );
        hiddenField.type = 'hidden';
        hiddenField.name = 'singleUseTokenId';
        hiddenField.value = singleUseTokenId;
        scope.formElement.appendChild( hiddenField );

        removeEvent( scope.formElement, 'submit', scope.formElement.payWaySubmitCallback );
        document.createElement( 'form' ).submit.call( scope.formElement );
    }

    function addEvent( elm, evType, fn, useCapture ) {
        //Credit: Function written by Scott Andrews
        //(slightly modified)
        var ret = 0;

        if ( elm.addEventListener ) {
            ret = elm.addEventListener( evType, fn, useCapture );
        } else if ( elm.attachEvent ) {
            ret = elm.attachEvent( 'on' + evType, fn );
        } else {
            elm['on' + evType] = fn;
        }

        return ret;
    }

    function removeEvent( elm, evType, fn ) {
        var ret = 0;

        if ( elm.removeEventListener ) {
            ret = elm.removeEventListener( evType, fn, false );
        } else if ( elm.removeEvent ) {
            ret = elm.removeEvent( 'on' + evType, fn );
        } else {
            elm['on' + evType] = null;
        }

        return ret;
    }

    function sendErrorToContainer( container, message ) {
        var containerElement = document.getElementById( container );
        if ( containerElement ) {
            var errorElement = document.createElement( 'p' );
            errorElement.style.cssText = "color: red; font-weight: bold;";
            errorElement.className = 'payway-frame-error';
            errorElement.innerHTML = message;
            containerElement.appendChild( errorElement );
        }
    }

    function findFormElement( container ) {
        var element = container;
        while ( element ) {
            if ( 'FORM' === element.nodeName.toUpperCase() ) {
                return element;
            }
            element = element.parentNode;
        }
    }

    function createFrame( scope, initFrameCallback ) {
        // Ensure we are ready to receive messages from the iframe.
        scope.messageListener = function( event ){ receiveMessage( event, scope ) };
        addEvent( window, 'message', scope.messageListener, false );

        var iframeClassName;
        var iframeSourceUrl;
        if ( scope.paymentMethod === 'creditCard' ) {
            iframeClassName = 'payway-credit-card-iframe';
            iframeSourceUrl = '/rest/v1/creditCard-iframe.htm';
        } else {
            iframeClassName = 'payway-bank-account-iframe';
            iframeSourceUrl = '/rest/v1/bankAccount-iframe.htm';
        }

        var iframe = document.createElement( 'iframe' );
        addEvent( iframe, 'load', function() { initFrameCallback( iframe ); }, false );
        iframe.id = iframeClassName + scope.frameId;
        iframe.src = payWayRestApiOrigin + iframeSourceUrl;
        iframe.sandbox = 'allow-forms allow-scripts allow-same-origin';
        iframe.width = scope.width;
        iframe.height = scope.height;
        iframe.scrolling = 'no';
        iframe.style.cssText = 'overflow: hidden;';
        iframe.frameBorder = '0';
        iframe.seamless = 'seamless';
        iframe.className = iframeClassName;

        scope.iframeElement = iframe;

        scope.containerElement.appendChild( iframe );
    }

    function sendMessageToFrame( messageType, scope, parameters ) {
        var message = {
            app: 'payway',
            type: messageType,
            frameId: scope.frameId
        };

        extend( message, parameters );

        scope.iframeElement.contentWindow.postMessage(
            JSON.stringify( message ), 
            payWayRestApiOrigin );
    }

    function validateOptions( options, createdCallback, paymentMethod ) {
        var createFrameMethodName;
        var defaultContainerName;
        if ( paymentMethod === 'creditCard' ) {
            createFrameMethodName = 'payway.createCreditCardFrame';
            defaultContainerName = 'payway-credit-card';
        } else {
            createFrameMethodName = 'payway.createBankAccountFrame';
            defaultContainerName = 'payway-bank-account';
        }

        var scope = {};
        scope.frameId = frameIdCounter;
        ++frameIdCounter;
        scope.paymentMethod = paymentMethod;

        var container = defaultContainerName;
        if ( !options ) {
            var error = 'You must provide options to ' + createFrameMethodName;
            log( error );
            sendErrorToContainer( container, error );
            return null;
        }

        if ( options.container ) {
            container = options.container;
        }

        var layoutError = false;
        var layoutProvided = false;
        if ( !options.hasOwnProperty( 'layout' ) ||
             typeof options.layout === 'null' ||
             typeof options.layout === 'undefined' ) {
            scope.layout = 'wide';
        } else if ( options.layout !== 'wide' &&
                    options.layout !== 'narrow' ) {
            layoutError = true;
            scope.layout = 'wide';
        } else {
            scope.layout = options.layout;
            layoutProvided = true;
        }

        if ( scope.layout === 'wide' ) {
            scope.width = 370;
            scope.height = 226;
        } else {
            scope.width = 278;
            scope.height = 306;
        }

        var widthError = false;
        var widthProvided = false;
        if ( !options.hasOwnProperty( 'width' ) ||
             typeof options.width === 'null' ||
             typeof options.width === 'undefined' ) {
            // Okay, take the default.
        } else if ( typeof options.width !== 'number' ) {
            widthError = true;
        } else {
            scope.width = options.width;
            widthProvided = true;
        }

        var heightError = false;
        var heightProvided = false;
        if ( !options.hasOwnProperty( 'height' ) ||
             typeof options.height === 'null' ||
             typeof options.height === 'undefined' ) {
            // Okay, take the default.
        } else if ( typeof options.height !== 'number' ) {
            heightError = true;
        } else {
            scope.height = options.height;
            heightProvided = true;
        }

        var createdCallbackError = false;
        if ( typeof createdCallback === 'null' ||
             typeof createdCallback === 'undefined' ) {
            scope.createdCallback = function(){};
        } else if ( typeof createdCallback !== 'function' ) {
            scope.createdCallback = function(){};
            createdCallbackError = true;
        } else {
            scope.createdCallback = createdCallback;
        }

        var containerError = false;
        scope.containerElement = document.getElementById( container );
        if ( !scope.containerElement ) {
            var error =
                'An element with id \'' + container + '\' could not be found in the document.'
                + '  You must create a div with id \'' + container + '\'';
            log( error );
            // No point attempting to send the error to the container here...
            onReady( scope, error );
            containerError = true;
        }

        if ( options.hasOwnProperty( 'tokenMode' ) &&
             options.tokenMode == 'callback' &&
            ( typeof createdCallback === 'null' ||
              typeof createdCallback === 'undefined')  ) {
           createFrame( scope, function(){
               sendMessageToFrame( 'tokenModeNoCallbackFunctionProvided', scope );
           } );
           return null;
        }

        if ( createdCallbackError && !containerError ) {
            createFrame( scope, function(){
                sendMessageToFrame( 'createdCallbackMustBeAFunction', scope );
            } );
        }

        if ( createdCallbackError || containerError ) {
            return null;
        }

        if ( !options.hasOwnProperty( 'onValid' ) ||
             typeof options.onValid === 'null' ||
             typeof options.onValid === 'undefined' ) {
            scope.onValid = function(){};
        } else if ( typeof options.onValid !== 'function' ) {
            createFrame( scope, function(){
                sendMessageToFrame( 'onValidMustBeAFunction', scope );
            } );
            return null;
        } else {
            scope.onValid = options.onValid;
        }

        if ( !options.hasOwnProperty( 'onInvalid' ) ||
             typeof options.onInvalid === 'null' ||
             typeof options.onInvalid === 'undefined' ) {
            scope.onInvalid = function(){};
        } else if ( typeof options.onInvalid !== 'function' ) {
            createFrame( scope, function(){
                sendMessageToFrame( 'onInvalidMustBeAFunction', scope );
            } );
            return null;
        } else {
            scope.onInvalid = options.onInvalid;
        }

        if ( !options.hasOwnProperty( 'tokenMode' ) ||
             typeof options.tokenMode === 'null' ||
             typeof options.tokenMode === 'undefined' ) {
            scope.tokenMode = 'post';
        } else if ( options.tokenMode !== 'callback' &&
                    options.tokenMode !== 'post' ) {
            createFrame( scope, function(){
                sendMessageToFrame( 'tokenModeNotValid', scope );
            } );
            return null;
        } else {
            scope.tokenMode = options.tokenMode;
        }

        if ( !options.hasOwnProperty( 'style' ) ||
             typeof options.style === 'null' ||
             typeof options.style === 'undefined' ) {
            scope.style = {};
        } else if ( typeof options.style !== 'object' ) {
            createFrame( scope, function(){
                sendMessageToFrame( 'styleNotValid', scope );
            } );
            return null;
        } else {
            scope.style = options.style;
        }

        if ( layoutError ) {
            createFrame( scope, function(){
                sendMessageToFrame( 'layoutNotValid', scope );
            } );
            return null;
        }

        if ( widthError ) {
            createFrame( scope, function(){
                sendMessageToFrame( 'widthNotValid', scope );
            } );
            return null;
        }

        if ( heightError ) {
            createFrame( scope, function(){
                sendMessageToFrame( 'heightNotValid', scope );
            } );
            return null;
        }

        var layoutAndDimensionsProvidedError =
            layoutProvided && ( widthProvided || heightProvided );

        if ( layoutAndDimensionsProvidedError ) {
            createFrame( scope, function(){
                sendMessageToFrame( 'layoutAndDimensionsProvidedError', scope );
            } );
            return null;
        }

        if ( scope.tokenMode === 'post' ) {
            scope.formElement = findFormElement( scope.containerElement );
            if ( !scope.formElement ) {
                createFrame( scope, function(){
                    sendMessageToFrame( 'containerMustBeInAForm', scope, { container: scope.containerElement.id } );
                } );
                return null;
            }

            if ( scope.formElement.paywayFrame ) {
                createFrame( scope, function(){
                    sendMessageToFrame( 'formAlreadyContainsPayWayFrame', scope );
                } );
                return null;
            }

            scope.formElement.paywayFrame = true;
        }

        return scope;
    }

    function createCreditCardOrBankAccountFrame( options, createdCallback, paymentMethod ) {
        var scope = validateOptions( options, createdCallback, paymentMethod );
        if ( !scope ) {
            return;
        }

        scope.publishableApiKey = options.publishableApiKey;
        scope.tokenCallbacks = {};
        scope.cvnRequired = options.cvnRequired;

        var initFrame = function( iframeElement, scope ) {
            // Send a message to the iframe telling it to initialise.
            var parameters = {
                publishableApiKey: scope.publishableApiKey,
                cvnRequired: scope.cvnRequired,
                style: scope.style,
                layout: scope.layout
            };
            sendMessageToFrame( 'getReady', scope, parameters );
        };
        var initFrameCallback = function( iframe ){
            initFrame( iframe, scope );
        };
        createFrame( scope, initFrameCallback );
    }

    return {
        createCreditCardFrame: function( options, createdCallback ) {
            createCreditCardOrBankAccountFrame( options, createdCallback, 'creditCard' );
        },
        createBankAccountFrame: function( options, createdCallback ) {
            createCreditCardOrBankAccountFrame( options, createdCallback, 'bankAccount' );
        }
    };
}());