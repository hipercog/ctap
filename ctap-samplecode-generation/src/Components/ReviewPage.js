import React from "react";
import { makeStyles } from '@material-ui/core/styles';
import SyntaxHighlighter from 'react-syntax-highlighter';
import { vs } from 'react-syntax-highlighter/dist/esm/styles/prism';
import Container from '@material-ui/core/Container';

const useStyles = makeStyles((theme) => ({
    root: {
        width: '100%',
        marginTop: 50,
        textAlign: "left"
    },

}));

const ReviewPage = (codeString) => {
    const classes = useStyles();

    return (
        <Container maxWidth='md' className={classes.root}>
            <SyntaxHighlighter language="matlab" 
                style={vs}
                showLineNumbers={true}
                codeTagProps={{ style: { fontFamiily: "times new roman" } }}
            >
                {codeString.codeString}
            </SyntaxHighlighter>
        </Container>

    )

}

export default ReviewPage;