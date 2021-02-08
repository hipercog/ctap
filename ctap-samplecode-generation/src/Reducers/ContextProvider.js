import React, { useReducer, createContext } from "react";
import { initialLinearInputState, initialBranchInputState, defaultBasicInfoInput, Reducer } from "./Reducer.js";

const ContextProvider = ({ children }) => {
    const [inputLinearState, dispatchL] = useReducer(Reducer, initialLinearInputState);
    const [inputBranchState, dispatchB] = useReducer(Reducer, initialBranchInputState);
    const [basicInfoInput, dispatch] = useReducer(Reducer, defaultBasicInfoInput);
    return (
        <ContextBasic.Provider value={[basicInfoInput, dispatch]}>
            <ContextLinear.Provider value={[inputLinearState, dispatchL]}>
                <ContextBranch.Provider value={[inputBranchState, dispatchB]}>
                    {children}
                </ContextBranch.Provider>
            </ContextLinear.Provider>
        </ContextBasic.Provider>


    )
}
export const ContextBranch = createContext(initialBranchInputState);
export const ContextLinear = createContext(initialLinearInputState);
export const ContextBasic = createContext(defaultBasicInfoInput);

export default ContextProvider