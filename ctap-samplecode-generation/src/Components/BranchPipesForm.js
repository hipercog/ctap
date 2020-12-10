import React, { useContext, useState } from "react";
import TextField from '@material-ui/core/TextField';
import Container from '@material-ui/core/Container';
import LinearPipesForm from "./LinearPipesForm";
import Select from '@material-ui/core/Select';
import InputLabel from '@material-ui/core/InputLabel';
import FormControl from '@material-ui/core/FormControl';
import { v4 as uuidv4 } from 'uuid';

import { ContextBranch } from './ContextProvider'
import { makeStyles } from '@material-ui/core/styles';

const useStyles = makeStyles((theme) => ({
    root: {
        '& .MuiTextField-root': {
            margin: theme.spacing(1),
        }
    },
    formControl: {
        margin: theme.spacing(1),
        minWidth: 200,
    }
}))

const BranchPipesForm = () => {
    const classes = useStyles()
    const [inputStates, dispatch] = useContext(ContextBranch);
    const [stepNum, setStepNum] = useState(1);

    const handleLinearPipesInput = (id, event) => {
        const newInputFields = inputStates.map(i => {
            if (id === i.id) {
                i[event.target.name] = event.target.value
                i[event.target.name + 'Check'] = false;
            }
            return i;
        })
        dispatch({ type: 'UPDATE_STEPSETS', data: newInputFields })
    }

    const handleChangeStepSets = (e, index) => {
        const { value } = e.target;
        if (stepNum < value) {
            let form = [...inputStates];
            for (let i = stepNum; i < value; i++) {
                form[index].linearSetting.push({ id: uuidv4(), stepID: '', stepIDCheck: false, funcsSettings: [{ fid: uuidv4(), funcName: '', funcP: '', funcNameCheck: false }] });
            }
            console.log(form)
            dispatch({ type: 'UPDATE_STEPSETS', data: form })
            setStepNum(value);
        } else if (stepNum > value && value >= 1) {
            console.log(inputStates)
            let form = [...inputStates];
            for (let i = 0; i < stepNum - value; i++) {
                form[index].linearSetting.pop();
            }
            dispatch({ type: 'UPDATE_STEPSETS', data: form })
            setStepNum(value);
        }
    }

    //  console.log(inputStates)
    return (
        <Container maxWidth="sm">
            <form className={classes.root}>
                {inputStates.map((inputField, index) => (
                    <div key={inputField.id}>
                        <h4>Pipe-segment {index + 1}</h4>
                        <TextField
                            error={inputField.stepIDCheck}
                            name="stepID"
                            label="pipeSegment Description Label"
                            variant="filled"
                            helperText={inputField.stepIDCheck ? 'The field cannot be empty. Please enter a value' : "describe main work in this pipeSegment, eg.'_load'"}
                            value={inputField.stepID}
                            onChange={event => handleLinearPipesInput(inputField.id, event)}
                        />
                        <h5>Define hierarchy</h5>
                        <TextField
                            error={inputField.pipeSegmentIDCheck}
                            name="pipeSegmentID"
                            label="pipeSegment ID"
                            variant="filled"
                            helperText={inputField.pipeSegmentIDCheck ? 'The field cannot be empty. Please enter a value' : "ID of this pipeSegment, eg.'pipe2'"}
                            value={inputField.pipeSegmentID}
                            onChange={event => handleLinearPipesInput(inputField.id, event)}
                        />
                        <TextField
                            error={inputField.pipeSegment_srcidCheck}
                            name="pipeSegment_srcid"
                            label="pipeSegment Srcid"
                            variant="filled"
                            helperText={inputField.pipeSegment_srcidCheck ? 'The field cannot be empty. Please enter a value' : "Describe the hierarchy relationship between other pipeSegment, you should input [Set Function ID] of the previously executed pipe, for example, if the current pipeSegment runs after pipe2, then the input should be 'pipe2', the first pipeSegment doesn't need this, leave it empty is ok."}
                            value={inputField.pipeSegment_srcid}
                            onChange={event => handleLinearPipesInput(inputField.id, event)}
                        />
                        <h5>Define pipeline</h5>
                        <FormControl variant="outlined" className={classes.formControl}>
                            <InputLabel > {'stepSet number'}</InputLabel>
                            <Select
                                native
                                value={stepNum}
                                onChange={e => handleChangeStepSets(e, index)}
                                label="stepSet number"
                                inputProps={{
                                    name: 'stepNum',
                                }}
                            >
                                {
                                    [1, 2, 3, 4, 5, 6, 7, 8, 9, 10].map(i => {
                                        return <option key={i} value={i}>{i}</option>
                                    })
                                }
                            </Select>
                        </FormControl>
                        <LinearPipesForm
                            ifLinear={false}
                            index={index}
                            mid={inputField.id} />
                    </div>
                ))}
            </form>
        </Container>
    );
}

export default BranchPipesForm;