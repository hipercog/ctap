import { v4 as uuidv4 } from 'uuid';

//pipeline reducer
export const initialLinearInputState = [{ id: uuidv4(), stepID: '', stepIDCheck: false, funcsSettings: [{ fid: uuidv4(), funcName: '', funcP: '', funcNameCheck: false }] }];
export const initialBranchInputState = [{ id: uuidv4(), stepNum: 1, pipeSegment_srcid: '', pipeSegmentID: '', stepID: '', pipeSegment_srcidCheck: false, pipeSegmentIDCheck: false, stepIDCheck: false, linearSettings: [{ id: uuidv4(), stepID: '', stepIDCheck: false, funcsSettings: [{ fid: uuidv4(), funcName: '', funcP: '', funcNameCheck: false }] }] }];
export const Reducer = (state, action) => {
    switch (action.type) {
        case 'UPDATE': {
            return action.data
        }
        default:
            return state;
    }
};

//basic info reducer
export const defaultBasicInfoInput = {
    checkedLinear: true,
    checkedBranch: false,
    checkedHYDRA: true,
    HydraOptionA: true,
    HydraOptionB: false,
    checkHydraTimeRange: "",
    checkHydraCleanSeed: "",
    pipelineName: "",
    inputdatapath: "ctap/data/test_data",
    checkOwnDataPath: false,
    projectRoot: "",
    sbj_filt: "",
    eegType: "",
    eegChanloc: "",
    eegReference: "",
    eegVeogChannelNames: "",
    eegHeogChannelNames: ""
};
