import React, { useContext, useState } from "react";
import clsx from 'clsx';
import TextField from '@material-ui/core/TextField';
import Container from '@material-ui/core/Container';
import LinearPipesForm from "./LinearPipesForm";
import Select from '@material-ui/core/Select';
import InputLabel from '@material-ui/core/InputLabel';
import FormControl from '@material-ui/core/FormControl';
import Tooltip from '@material-ui/core/Tooltip';
import Typography from "@material-ui/core/Typography";
import { v4 as uuidv4 } from 'uuid';

import { ContextBranch } from '../Reducers/ContextProvider'
import { makeStyles } from '@material-ui/core/styles';

const useStyles = makeStyles((theme) => ({
    margin: {
        margin: theme.spacing(1),
    },
    withoutLabel: {
        marginTop: theme.spacing(1),
    },
    textField: {
        width: '25ch',
    },
    customWidth: {
        maxWidth: 500,
    },
}));

const helperText = {
    stepID: "describe main work in this pipeSegment, eg.'_load'",
    pipeSegmentID: "ID of this pipeSegment, eg.'pipe2'",
    pipeSegment_srcid: "Describe the hierarchy relationship between other pipeSegment, you should input [Set Function ID] of the previously executed pipe, for example, if the current pipeSegment runs after pipe2, then the input should be 'pipe2', the first pipeSegment doesn't need this, leave it empty is ok."
};

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
            dispatch({ type: 'UPDATE_STEPSETS', data: form })
            setStepNum(value);
        } else if (stepNum > value && value >= 1) {
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
        <Container maxWidth="md">
            {inputStates.map((inputField, index) => (
                <div key={inputField.id}>
                    <h4>Pipe-segment {index + 1}</h4>
                    <FormControl className={clsx(classes.margin, classes.textField, classes.withoutLabel)}>
                        <Tooltip title={<Typography variant='body2'>{helperText.stepID}</Typography>} classes={{ tooltip: classes.customWidth }}>
                            <TextField
                                error={inputField.stepIDCheck}
                                name="stepID"
                                label="pipeSegment Description Label"
                                variant="outlined"
                                helperText={inputField.stepIDCheck ? 'The field cannot be empty. Please enter a value' : null}
                                value={inputField.stepID}
                                onChange={event => handleLinearPipesInput(inputField.id, event)}
                            />
                        </Tooltip>
                    </FormControl>


                    <h5>Define hierarchy</h5>
                    <FormControl className={clsx(classes.margin, classes.textField, classes.withoutLabel,)}>
                        <Tooltip title={<Typography variant='body2'>{helperText.pipeSegmentID}</Typography>} classes={{ tooltip: classes.customWidth }}>
                            <TextField
                                error={inputField.pipeSegmentIDCheck}
                                name="pipeSegmentID"
                                label="pipeSegment ID"
                                variant="outlined"
                                helperText={inputField.pipeSegmentIDCheck ? 'The field cannot be empty. Please enter a value' : null}
                                value={inputField.pipeSegmentID}
                                onChange={event => handleLinearPipesInput(inputField.id, event)}
                            />
                        </Tooltip>
                    </FormControl>
                    <FormControl className={clsx(classes.margin, classes.textField, classes.withoutLabel,)}>
                        <Tooltip title={<Typography variant='body2'>{helperText.pipeSegment_srcid}</Typography>} classes={{ tooltip: classes.customWidth }}>
                            <TextField
                                error={inputField.pipeSegment_srcidCheck}
                                name="pipeSegment_srcid"
                                label="pipeSegment Srcid"
                                variant="outlined"
                                helperText={inputField.pipeSegment_srcidCheck ? 'The field cannot be empty. Please enter a value' : null}
                                value={inputField.pipeSegment_srcid}
                                onChange={event => handleLinearPipesInput(inputField.id, event)}
                            />
                        </Tooltip>
                    </FormControl>


                    <h5>Define pipeline</h5>
                    <FormControl variant="outlined" className={clsx(classes.margin, classes.textField, classes.withoutLabel)}>
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

        </Container >
    );
}

export default BranchPipesForm;