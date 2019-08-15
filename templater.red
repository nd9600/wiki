Red [
    Title: "Nathan's templater compiler"
    Author: "Nathan Douglas"
    License: "MIT"
]

compile: function [
    input_string    [string!]   "the input to compile"
    variables       [map!]    "the variables to use to compile the input string"
] [        
    whitespace:     [#" " | tab | newline]
    digit:          charset "0123456789"
    letter:         charset [#"A" - #"Z" #"a" - #"z" ]
    other_char:     charset ["_" "-" "/"]
    alphanum:       union letter digit
    any_character:  complement make bitset! []
        
    ; a variable name must start with a letter and can be followed by a series of letters, digits or underscores or dashes
    variable: [letter any [alphanum | other_char]]
    
    ; copy any character into the output
    anything: [copy data any_character (append output data)]
    
    ; copy escaped left braces nto the output
    escaped_left_braces: [copy data "\{{" (append output data)]
    
    ; copy the value of a variable into the output, or "none" if the variable doesn't exist
    template_variable: [
        ["{{" any whitespace copy data variable any whitespace "}}"]
        (
            variablePath: append copy "variables/" data
            
            ; we have to bind actualVariablePath to this context or 'variables isn't defined for some reason
            actualVariablePath: load/all variablePath
            actualVariable: do bind actualVariablePath 'variables
            
            either (block? actualVariable) [
                append output mold actualVariable
            ] [
                append output actualVariable
            ]
        )
    ]
    
    escaped_left_brace_and_percent: [copy data "\{%" (append output data)]
    
    ; when you want to copy to (not thru) multiple things, like {% endif %}, make sure you put it in a block!
    if_statement: [
        [
            "{%" any whitespace "if" some whitespace 
                copy ifCondition to "%}" "%}"
            copy stringToCompile to
            ["{%" any whitespace "endif" any whitespace "%}"]
            ["{%" any whitespace "endif" any whitespace "%}"]
        ]
        (
            do to-block variables
            actualIfCondition: do load ifCondition
            if actualIfCondition [
                compiledText: copy (compile stringToCompile variables)
                append output compiledText
            ]
        )
    ]
    
    for_loop: [
        [
            "{%" any whitespace "for" 
                some whitespace copy iteratorIndex variable
            some whitespace "in" 
                some whitespace copy thingToIterateOver variable
            any whitespace "%}"
                copy stringToCompileRepeatedly to
                [ "{%" any whitespace "endfor" any whitespace "%}" ]
                [ "{%" any whitespace "endfor" any whitespace "%}" ]
        ]
        (
            iteratorIndexAsVariable: to-word iteratorIndex
            
            thingToIterateOver: to-word thingToIterateOver
            actualThingToIterateOver: select variables thingToIterateOver
            
            foreach i actualThingToIterateOver [
                thisIterationsVariables: copy variables
                put thisIterationsVariables :iteratorIndexAsVariable :i
                
                compiledText: copy (compile stringToCompileRepeatedly thisIterationsVariables)
                append output compiledText
            ]
        )
    ]
    
    ;'comment is already defined in rebol
    comment_rule: [ "{#" thru "#}" ]
    
    rules: [
        any [
                escaped_left_braces
            |
                template_variable
            |
                escaped_left_brace_and_percent
            |
                if_statement
            |
                for_loop
            |
                comment_rule
            |
                anything
        ]  
    ]
    
    output: copy ""
    parse input_string rules
    output
]
