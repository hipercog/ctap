import React, { useReducer, createContext} from "react";
import { initialInputState, Reducer } from "../Reducer.js";

const ContextProvider = ({children}) =>{
    const [inputState, dispatch] = useReducer(Reducer, initialInputState);
    return (
        <Context.Provider value={[inputState, dispatch]}>
            {children}
        </Context.Provider>
    )
}
export const Context = createContext(initialInputState);
export default ContextProvider