import { v4 as uuidv4 } from 'uuid';
export const initialInputState = [{ id: uuidv4(), subf_srcid: '', subfID: '', stepID: '', funcsSettings: [{ fid: uuidv4(), funcName: '', funcP: '' }] }];

export const Reducer = (state, action) => {
    switch (action.type) {
        case 'UPDATE_STEPSETS': {
            return action.data
        }
        default:
            return state;


    }

};

