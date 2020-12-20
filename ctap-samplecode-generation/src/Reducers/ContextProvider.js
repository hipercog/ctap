import React, { useReducer, createContext } from "react";
import { initialLinearInputState, initialBranchInputState, Reducer } from "./Reducer.js";

const ContextProvider = ({ children }) => {
    const [inputLinearState, dispatchL] = useReducer(Reducer, initialLinearInputState);
    const [inputBranchState, dispatchB] = useReducer(Reducer, initialBranchInputState);
    return (

        <ContextLinear.Provider value={[inputLinearState, dispatchL]}>
            <ContextBranch.Provider value={[inputBranchState, dispatchB]}>
                {children}
            </ContextBranch.Provider>
        </ContextLinear.Provider>

    )
}
export const ContextBranch = createContext(initialBranchInputState);
export const ContextLinear = createContext(initialLinearInputState);

export default ContextProvider