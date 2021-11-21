precedencegroup SingleFowardPipe {
    associativity: left
    higherThan: BitwiseShiftPrecedence
}

infix operator |> : SingleFowardPipe

func |> <V,R>(value:V,function:((V)->R)) -> R {
    function(value)
}

